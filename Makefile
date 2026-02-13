# -------------------------
# Toolchain (user-overridable)
# -------------------------
FC     ?= gfortran
AR     ?= ar
RANLIB ?= ranlib

# -------------------------
# Flags
# -------------------------
FFLAGS  ?= -O2 -Wall -Wextra -std=f2008
LDFLAGS ?=

# -------------------------
# Sources
# -------------------------
SRC     := src/mod_coulcc37.f90
TESTSRC := tests/test_coulcc.f90

# -------------------------
# Build dirs
# -------------------------
BUILDDIR := build
OBJDIR   := $(BUILDDIR)/obj
MODDIR   := $(BUILDDIR)/mod
INCDIR   := $(BUILDDIR)/include
LIBDIR   := $(BUILDDIR)/lib
BINDIR   := $(BUILDDIR)/bin

# -------------------------
# Outputs
# -------------------------
OBJ      := $(OBJDIR)/mod_coulcc37.o
OBJ_PIC  := $(OBJDIR)/mod_coulcc37_pic.o
TESTOBJ  := $(OBJDIR)/test_coulcc.o

# Library naming policy: package name = coulcc
STATICLIB := $(LIBDIR)/libcoulcc.a
SHAREDLIB := $(LIBDIR)/libcoulcc.so

# -------------------------
# Public module export (hide internal .mod files)
# -------------------------
PUBLIC_MOD          := mod_coulcc.mod
PUBLIC_MOD_IN_BUILD := $(MODDIR)/$(PUBLIC_MOD)
PUBLIC_MOD_PATH     := $(INCDIR)/$(PUBLIC_MOD)

# -------------------------
# Install (staging) dirs
# -------------------------
PREFIX      ?= $(BUILDDIR)/install
INSTALL_LIB := $(PREFIX)/lib
INSTALL_INC := $(PREFIX)/include

.PHONY: all dirs clean static shared test test_static test_shared run export_mod install uninstall

all: static shared test

dirs:
	@mkdir -p $(OBJDIR) $(MODDIR) $(INCDIR) $(LIBDIR) $(BINDIR)

# -------------------------
# Compile objects
# -------------------------
$(OBJ): $(SRC) | dirs
	$(FC) $(FFLAGS) -J$(MODDIR) -I$(MODDIR) -c $< -o $@

$(OBJ_PIC): $(SRC) | dirs
	$(FC) $(FFLAGS) -fPIC -J$(MODDIR) -I$(MODDIR) -c $< -o $@

# -------------------------
# Static library
# -------------------------
static: $(STATICLIB) export_mod

$(STATICLIB): $(OBJ) | dirs
	$(AR) rcs $@ $^
	$(RANLIB) $@

# -------------------------
# Shared library
# -------------------------
shared: $(SHAREDLIB) export_mod

$(SHAREDLIB): $(OBJ_PIC) | dirs
	$(FC) -shared -o $@ $^

# -------------------------
# Export only public .mod
# -------------------------
export_mod: $(PUBLIC_MOD_PATH)

$(PUBLIC_MOD_PATH): $(OBJ) | dirs
	@test -f "$(PUBLIC_MOD_IN_BUILD)" || ( \
	  echo "ERROR: public .mod not found: $(PUBLIC_MOD_IN_BUILD)"; \
	  echo "Contents of $(MODDIR):"; ls -l "$(MODDIR)"; \
	  exit 1 )
	cp -f "$(PUBLIC_MOD_IN_BUILD)" "$@"
	@echo "Exported public module: $@"

# -------------------------
# Tests
#   - compile tests ONLY against exported public .mod (INCDIR)
#   - do NOT add -I$(MODDIR) here, to ensure internals stay hidden
# -------------------------
$(TESTOBJ): $(TESTSRC) export_mod | dirs
	$(FC) $(FFLAGS) -J$(MODDIR) -I$(INCDIR) -c $< -o $@

test: test_static test_shared
test_static: $(BINDIR)/test_static.exe
test_shared: $(BINDIR)/test_shared.exe

$(BINDIR)/test_static.exe: $(TESTOBJ) $(STATICLIB) | dirs
	$(FC) -o $@ $(TESTOBJ) $(STATICLIB) $(LDFLAGS)

# rpath so the executable can find build/lib/libcoulcc.so without LD_LIBRARY_PATH
$(BINDIR)/test_shared.exe: $(TESTOBJ) $(SHAREDLIB) | dirs
	$(FC) -o $@ $(TESTOBJ) -L$(LIBDIR) -lcoulcc \
	    -Wl,-rpath,'$$ORIGIN/../lib' $(LDFLAGS)

run: test
	@echo "== static =="
	$(BINDIR)/test_static.exe
	@echo "== shared =="
	$(BINDIR)/test_shared.exe

# -------------------------
# Install
#   Installs ONLY:
#     - public .mod  (mod_coulcc.mod)
#     - libraries    (libcoulcc.a / libcoulcc.so)
#   to:
#     $(PREFIX)/include
#     $(PREFIX)/lib
# -------------------------
install: static shared export_mod
	@mkdir -p $(INSTALL_LIB) $(INSTALL_INC)
	cp -f $(STATICLIB) $(INSTALL_LIB)/
	cp -f $(SHAREDLIB) $(INSTALL_LIB)/
	cp -f $(PUBLIC_MOD_PATH) $(INSTALL_INC)/
	@echo "Installed to: $(PREFIX)"
	@echo "  include: $(INSTALL_INC)/$(PUBLIC_MOD)"
	@echo "  lib:     $(INSTALL_LIB)/$$(basename $(STATICLIB))"
	@echo "  lib:     $(INSTALL_LIB)/$$(basename $(SHAREDLIB))"

# Optional convenience (best-effort)
uninstall:
	@rm -f $(INSTALL_INC)/$(PUBLIC_MOD)
	@rm -f $(INSTALL_LIB)/$$(basename $(STATICLIB))
	@rm -f $(INSTALL_LIB)/$$(basename $(SHAREDLIB))
	@echo "Uninstalled from: $(PREFIX)"

clean:
	rm -rf $(BUILDDIR)
