local M = {}

-- ── Helpers ─────────────────────────────────────────────────────────

local type_map = {
  ["Executable"] = "exe",
  ["Static Library"] = "static",
  ["Shared Library"] = "shared",
  ["Header-only Library"] = "header_only",
  ["Library + Executable"] = "lib_exe",
}

local function std_num(std)
  return std:match("%d+")
end

local function guard(name, ext)
  return name:upper():gsub("[^%w]", "_") .. "_" .. ext:upper()
end

local function src_ext(lang)
  return lang == "C" and "c" or "cpp"
end

local function hdr_ext(lang)
  return lang == "C" and "h" or "hpp"
end

local function cmake_lang(lang)
  return lang == "C" and "C" or "CXX"
end

local function cmake_std_block(lang, std)
  local p = lang == "C" and "C" or "CXX"
  return ("set(CMAKE_%s_STANDARD %s)\nset(CMAKE_%s_STANDARD_REQUIRED ON)"):format(
    p,
    std_num(std),
    p
  )
end

local function meson_lang(lang)
  return lang == "C" and "c" or "cpp"
end

local function meson_std_opt(lang, std)
  if lang == "C" then
    return ("'c_std=%s'"):format(std)
  else
    return ("'cpp_std=%s'"):format(std)
  end
end

local function make_compiler_block(lang, std)
  if lang == "C" then
    return ("CC       := gcc\nCFLAGS   := -std=%s -Wall -Wextra -pedantic"):format(std)
  else
    return ("CXX      := g++\nCXXFLAGS := -std=%s -Wall -Wextra -pedantic"):format(std)
  end
end

local function make_cc(lang)
  return lang == "C" and "$(CC)" or "$(CXX)"
end

local function make_flags(lang)
  return lang == "C" and "$(CFLAGS)" or "$(CXXFLAGS)"
end

local function make_compile_rule(lang)
  local se = src_ext(lang)
  return ("%%.o: %%.%s\n\t%s %s -c -o $@ $<"):format(se, make_cc(lang), make_flags(lang))
end

local function prefix(name)
  return name:lower():gsub("[^%w]", "_")
end

-- ── Source file content ────────────────────────────────────────────

local function main_c(name)
  return [[#include <stdio.h>

int main(int argc, char *argv[]) {
    (void)argc;
    (void)argv;
    printf("Hello from ]] .. name .. [[!\n");
    return 0;
}
]]
end

local function main_cpp(name)
  return [[#include <iostream>

int main(int argc, char *argv[]) {
    (void)argc;
    (void)argv;
    std::cout << "Hello from ]] .. name .. [[!" << std::endl;
    return 0;
}
]]
end

local function main_with_lib_c(name)
  local p = prefix(name)
  return ([[#include <stdio.h>
#include "%s.h"

int main(int argc, char *argv[]) {
    (void)argc;
    (void)argv;
    printf("%%d\n", %s_add(2, 3));
    return 0;
}
]]):format(name, p)
end

local function main_with_lib_cpp(name)
  return ([[#include <iostream>
#include "%s.hpp"

int main(int argc, char *argv[]) {
    (void)argc;
    (void)argv;
    std::cout << %s::add(2, 3) << std::endl;
    return 0;
}
]]):format(name, prefix(name))
end

local function lib_header_c(name)
  local g = guard(name, "h")
  local p = prefix(name)
  return ([[#ifndef %s
#define %s

int %s_add(int a, int b);

#endif /* %s */
]]):format(g, g, p, g)
end

local function lib_header_cpp(name)
  local g = guard(name, "hpp")
  local ns = prefix(name)
  return ([[#ifndef %s
#define %s

namespace %s {

int add(int a, int b);

} // namespace %s

#endif // %s
]]):format(g, g, ns, ns, g)
end

local function lib_source_c(name)
  local p = prefix(name)
  return ([[#include "%s.h"

int %s_add(int a, int b) {
    return a + b;
}
]]):format(name, p)
end

local function lib_source_cpp(name)
  local ns = prefix(name)
  return ([[#include "%s.hpp"

namespace %s {

int add(int a, int b) {
    return a + b;
}

} // namespace %s
]]):format(name, ns, ns)
end

local function header_only_c(name)
  local g = guard(name, "h")
  local p = prefix(name)
  return ([[#ifndef %s
#define %s

/* Define %s_IMPLEMENTATION in exactly one .c file before including. */

#ifdef %s_IMPLEMENTATION

int %s_add(int a, int b) {
    return a + b;
}

#endif /* %s_IMPLEMENTATION */

int %s_add(int a, int b);

#endif /* %s */
]]):format(g, g, p:upper(), p:upper(), p, p:upper(), p, g)
end

local function header_only_cpp(name)
  local g = guard(name, "hpp")
  local ns = prefix(name)
  return ([[#ifndef %s
#define %s

namespace %s {

inline int add(int a, int b) {
    return a + b;
}

} // namespace %s

#endif // %s
]]):format(g, g, ns, ns, g)
end

-- ── Source file paths ──────────────────────────────────────────────
--
-- Layout per project type:
--   Executable           src/main.c|cpp
--   Static Library       include/name.h|hpp  src/name.c|cpp
--   Shared Library       include/name.h|hpp  src/name.c|cpp
--   Header-only Library  include/name.h|hpp
--   Library + Executable include/name.h|hpp  src/name.c|cpp  src/main.c|cpp

function M.source_files(opts)
  local name = opts.name
  local lang = opts.language
  local ptype = type_map[opts.project_type]
  local se = src_ext(lang)
  local he = hdr_ext(lang)
  local files = {}

  if ptype == "exe" then
    local main_fn = lang == "C" and main_c or main_cpp
    files["src/main." .. se] = main_fn(name)
  elseif ptype == "static" or ptype == "shared" then
    local hdr_fn = lang == "C" and lib_header_c or lib_header_cpp
    local src_fn = lang == "C" and lib_source_c or lib_source_cpp
    files["include/" .. name .. "." .. he] = hdr_fn(name)
    files["src/" .. name .. "." .. se] = src_fn(name)
  elseif ptype == "header_only" then
    local hdr_fn = lang == "C" and header_only_c or header_only_cpp
    files["include/" .. name .. "." .. he] = hdr_fn(name)
  elseif ptype == "lib_exe" then
    local hdr_fn = lang == "C" and lib_header_c or lib_header_cpp
    local src_fn = lang == "C" and lib_source_c or lib_source_cpp
    local main_fn = lang == "C" and main_with_lib_c or main_with_lib_cpp
    files["include/" .. name .. "." .. he] = hdr_fn(name)
    files["src/" .. name .. "." .. se] = src_fn(name)
    files["src/main." .. se] = main_fn(name)
  end

  return files
end

-- ── CMake ───────────────────────────────────────────────────────────

M.cmake = {}

function M.cmake.exe(opts)
  local se = src_ext(opts.language)
  return "CMakeLists.txt",
    ([[cmake_minimum_required(VERSION 3.20)
project(%s LANGUAGES %s)

%s
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_executable(%s src/main.%s)
]]):format(
      opts.name,
      cmake_lang(opts.language),
      cmake_std_block(opts.language, opts.standard),
      opts.name,
      se
    )
end

function M.cmake.static(opts)
  local se = src_ext(opts.language)
  return "CMakeLists.txt",
    ([[cmake_minimum_required(VERSION 3.20)
project(%s LANGUAGES %s)

%s
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_library(%s STATIC src/%s.%s)
target_include_directories(%s PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
]]):format(
      opts.name,
      cmake_lang(opts.language),
      cmake_std_block(opts.language, opts.standard),
      opts.name,
      opts.name,
      se,
      opts.name
    )
end

function M.cmake.shared(opts)
  local se = src_ext(opts.language)
  return "CMakeLists.txt",
    ([[cmake_minimum_required(VERSION 3.20)
project(%s LANGUAGES %s)

%s
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_library(%s SHARED src/%s.%s)
target_include_directories(%s PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)
set_target_properties(%s PROPERTIES POSITION_INDEPENDENT_CODE ON)
]]):format(
      opts.name,
      cmake_lang(opts.language),
      cmake_std_block(opts.language, opts.standard),
      opts.name,
      opts.name,
      se,
      opts.name,
      opts.name
    )
end

function M.cmake.header_only(opts)
  return "CMakeLists.txt",
    ([[cmake_minimum_required(VERSION 3.20)
project(%s LANGUAGES %s)

%s

add_library(%s INTERFACE)
target_include_directories(%s INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/include)
]]):format(
      opts.name,
      cmake_lang(opts.language),
      cmake_std_block(opts.language, opts.standard),
      opts.name,
      opts.name
    )
end

function M.cmake.lib_exe(opts)
  local se = src_ext(opts.language)
  local lib = opts.name .. "_lib"
  return "CMakeLists.txt",
    ([[cmake_minimum_required(VERSION 3.20)
project(%s LANGUAGES %s)

%s
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_library(%s STATIC src/%s.%s)
target_include_directories(%s PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include)

add_executable(%s src/main.%s)
target_link_libraries(%s PRIVATE %s)
]]):format(
      opts.name,
      cmake_lang(opts.language),
      cmake_std_block(opts.language, opts.standard),
      lib,
      opts.name,
      se,
      lib,
      opts.name,
      se,
      opts.name,
      lib
    )
end

-- ── Make ────────────────────────────────────────────────────────────

M.make = {}

function M.make.exe(opts)
  local se = src_ext(opts.language)
  return "Makefile",
    ([[%s
LDFLAGS  :=

TARGET := %s
SRCS   := src/main.%s
OBJS   := $(SRCS:.%s=.o)

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJS)
	%s $(LDFLAGS) -o $@ $^

%s

clean:
	$(RM) $(TARGET) $(OBJS)
]]):format(
      make_compiler_block(opts.language, opts.standard),
      opts.name,
      se,
      se,
      make_cc(opts.language),
      make_compile_rule(opts.language)
    )
end

function M.make.static(opts)
  local se = src_ext(opts.language)
  return "Makefile",
    ([[%s -Iinclude
AR       := ar

TARGET := lib%s.a
SRCS   := src/%s.%s
OBJS   := $(SRCS:.%s=.o)

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJS)
	$(AR) rcs $@ $^

%s

clean:
	$(RM) $(TARGET) $(OBJS)
]]):format(
      make_compiler_block(opts.language, opts.standard),
      opts.name,
      opts.name,
      se,
      se,
      make_compile_rule(opts.language)
    )
end

function M.make.shared(opts)
  local se = src_ext(opts.language)
  return "Makefile",
    ([[%s -Iinclude -fPIC
LDFLAGS  := -shared

TARGET := lib%s.so
SRCS   := src/%s.%s
OBJS   := $(SRCS:.%s=.o)

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJS)
	%s $(LDFLAGS) -o $@ $^

%s

clean:
	$(RM) $(TARGET) $(OBJS)
]]):format(
      make_compiler_block(opts.language, opts.standard),
      opts.name,
      opts.name,
      se,
      se,
      make_cc(opts.language),
      make_compile_rule(opts.language)
    )
end

function M.make.header_only(opts)
  local he = hdr_ext(opts.language)
  return "Makefile",
    ([[PREFIX   ?= /usr/local
HEADER   := include/%s.%s

.PHONY: install uninstall

install:
	install -d $(DESTDIR)$(PREFIX)/include
	install -m 644 $(HEADER) $(DESTDIR)$(PREFIX)/include/

uninstall:
	$(RM) $(DESTDIR)$(PREFIX)/include/%s.%s
]]):format(opts.name, he, opts.name, he)
end

function M.make.lib_exe(opts)
  local se = src_ext(opts.language)
  local lib = "lib" .. opts.name .. ".a"
  return "Makefile",
    ([[%s -Iinclude
LDFLAGS  :=
AR       := ar

LIB      := %s
LIB_SRCS := src/%s.%s
LIB_OBJS := $(LIB_SRCS:.%s=.o)

TARGET   := %s
APP_SRCS := src/main.%s
APP_OBJS := $(APP_SRCS:.%s=.o)

.PHONY: all clean

all: $(TARGET)

$(LIB): $(LIB_OBJS)
	$(AR) rcs $@ $^

$(TARGET): $(APP_OBJS) $(LIB)
	%s $(LDFLAGS) -o $@ $(APP_OBJS) $(LIB)

%s

clean:
	$(RM) $(TARGET) $(LIB) $(LIB_OBJS) $(APP_OBJS)
]]):format(
      make_compiler_block(opts.language, opts.standard),
      lib,
      opts.name,
      se,
      se,
      opts.name,
      se,
      se,
      make_cc(opts.language),
      make_compile_rule(opts.language)
    )
end

-- ── Meson ───────────────────────────────────────────────────────────

M.meson = {}

function M.meson.exe(opts)
  local se = src_ext(opts.language)
  return "meson.build",
    ([[project('%s', '%s',
  version : '0.1.0',
  default_options : [%s, 'warning_level=3'])

executable('%s', 'src/main.%s',
  install : true)
]]):format(
      opts.name,
      meson_lang(opts.language),
      meson_std_opt(opts.language, opts.standard),
      opts.name,
      se
    )
end

function M.meson.static(opts)
  local se = src_ext(opts.language)
  return "meson.build",
    ([[project('%s', '%s',
  version : '0.1.0',
  default_options : [%s, 'warning_level=3'])

inc = include_directories('include')

%s_lib = static_library('%s', 'src/%s.%s',
  include_directories : inc,
  install : true)

%s_dep = declare_dependency(
  link_with : %s_lib,
  include_directories : inc)
]]):format(
      opts.name,
      meson_lang(opts.language),
      meson_std_opt(opts.language, opts.standard),
      prefix(opts.name),
      opts.name,
      opts.name,
      se,
      prefix(opts.name),
      prefix(opts.name)
    )
end

function M.meson.shared(opts)
  local se = src_ext(opts.language)
  return "meson.build",
    ([[project('%s', '%s',
  version : '0.1.0',
  default_options : [%s, 'warning_level=3'])

inc = include_directories('include')

%s_lib = shared_library('%s', 'src/%s.%s',
  include_directories : inc,
  install : true)

%s_dep = declare_dependency(
  link_with : %s_lib,
  include_directories : inc)
]]):format(
      opts.name,
      meson_lang(opts.language),
      meson_std_opt(opts.language, opts.standard),
      prefix(opts.name),
      opts.name,
      opts.name,
      se,
      prefix(opts.name),
      prefix(opts.name)
    )
end

function M.meson.header_only(opts)
  local he = hdr_ext(opts.language)
  return "meson.build",
    ([[project('%s', '%s',
  version : '0.1.0',
  default_options : [%s, 'warning_level=3'])

inc = include_directories('include')

%s_dep = declare_dependency(
  include_directories : inc)

install_headers('include/%s.%s')
]]):format(
      opts.name,
      meson_lang(opts.language),
      meson_std_opt(opts.language, opts.standard),
      prefix(opts.name),
      opts.name,
      he
    )
end

function M.meson.lib_exe(opts)
  local se = src_ext(opts.language)
  return "meson.build",
    ([[project('%s', '%s',
  version : '0.1.0',
  default_options : [%s, 'warning_level=3'])

inc = include_directories('include')

%s_lib = static_library('%s_lib', 'src/%s.%s',
  include_directories : inc)

%s_dep = declare_dependency(
  link_with : %s_lib,
  include_directories : inc)

executable('%s', 'src/main.%s',
  dependencies : %s_dep,
  install : true)
]]):format(
      opts.name,
      meson_lang(opts.language),
      meson_std_opt(opts.language, opts.standard),
      prefix(opts.name),
      opts.name,
      opts.name,
      se,
      prefix(opts.name),
      prefix(opts.name),
      opts.name,
      se,
      prefix(opts.name)
    )
end

-- ── .gitignore ──────────────────────────────────────────────────────

function M.gitignore()
  return [[# Build artifacts
build/
builddir/
*.o
*.d
*.a
*.so
*.so.*
*.dylib
*.dll
*.lib
*.exe

# CMake
CMakeCache.txt
CMakeFiles/
cmake_install.cmake
compile_commands.json
install_manifest.txt
CTestTestfile.cmake

# Meson
meson-logs/
meson-private/
meson-info/

# IDE
.vscode/
.idea/
.cache/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
]]
end

-- ── .clangd ─────────────────────────────────────────────────────────

function M.clangd(opts)
  local sys = system_map[opts.build_system] or opts.build_system
  local db_dir = ""
  if sys == "cmake" then
    db_dir = opts._cmake_build_dir or "build"
  elseif sys == "meson" then
    db_dir = opts._meson_build_dir or "builddir"
  end

  if db_dir ~= "" then
    return ("CompileFlags:\n  CompilationDatabase: %s\n"):format(db_dir)
  end

  -- Make: no compile_commands.json by default, just anchor the root
  return "CompileFlags:\n  Add: [-Iinclude]\n"
end

-- ── Main entry ──────────────────────────────────────────────────────

local system_map = {
  ["CMake"] = "cmake",
  ["Make"] = "make",
  ["Meson"] = "meson",
}

---Generate all project files.
---@param opts table { name, build_system, language, project_type, standard, gitignore }
---@return table<string, string> filename→content
function M.generate(opts)
  local ptype = type_map[opts.project_type]
  local sys = system_map[opts.build_system] or opts.build_system
  local files = {}

  -- Build file
  local gen = M[sys] and M[sys][ptype]
  if gen then
    local fname, content = gen(opts)
    files[fname] = content
  end

  -- Source files
  for fname, content in pairs(M.source_files(opts)) do
    files[fname] = content
  end

  -- .clangd (anchors clangd root + sets compile_commands path)
  files[".clangd"] = M.clangd(opts)

  -- .gitignore
  if opts.gitignore then
    files[".gitignore"] = M.gitignore()
  end

  return files
end

return M
