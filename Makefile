include Makefile.defs

all: koreader-base extr

koreader-base: koreader-base.o einkfb.o pdf.o blitbuffer.o drawcontext.o koptcontext.o input.o $(POPENNSLIB) util.o ft.o lfs.o mupdfimg.o $(MUPDFLIBS) $(THIRDPARTYLIBS) $(LUALIB) djvu.o $(DJVULIBS) cre.o $(CRELIB) $(CRE_3RD_LIBS) pic.o pic_jpeg.o $(K2PDFOPTLIB)
	$(CC) \
		$(CFLAGS) \
		koreader-base.o \
		einkfb.o \
		pdf.o \
		blitbuffer.o \
		drawcontext.o \
		koptcontext.o \
		input.o \
		$(POPENNSLIB) \
		util.o \
		ft.o \
		lfs.o \
		mupdfimg.o \
		pic.o \
		pic_jpeg.o \
		$(MUPDFLIBS) \
		$(THIRDPARTYLIBS) \
		djvu.o \
		cre.o \
		$(STATICLIBSTDCPP) \
		$(LDFLAGS) \
		-Wl,-rpath=$(LIBDIR)/ \
		-o $@ \
		-lm -ldl -lpthread -lk2pdfopt -ldjvulibre -lluajit-5.1 -lcrengine \
		-L$(MUPDFLIBDIR) -L$(LIBDIR) \
		$(CRE_3RD_LIBS) \
		$(EMU_LDFLAGS) \
		$(DYNAMICLIBSTDCPP)

extr:	extr.o $(MUPDFLIBS) $(THIRDPARTYLIBS)
	$(CC) $(CFLAGS) extr.o $(MUPDFLIBS) $(THIRDPARTYLIBS) -lm -o extr

extr.o:	%.o: %.c
	$(CC) -c -I$(MUPDFDIR)/pdf -I$(MUPDFDIR)/fitz $< -o $@

slider_watcher.o: %.o: %.c
	$(CC) -c $(CFLAGS) $< -o $@

slider_watcher: slider_watcher.o $(POPENNSLIB)
	$(CC) $(CFLAGS) slider_watcher.o $(POPENNSLIB) -o $@

ft.o: %.o: %.c $(THIRDPARTYLIBS)
	$(CC) -c $(KOREADER_BASE_CFLAGS) -I$(FREETYPEDIR)/include -I$(MUPDFDIR)/fitz $< -o $@

blitbuffer.o util.o drawcontext.o einkfb.o input.o mupdfimg.o: %.o: %.c
	$(CC) -c $(KOREADER_BASE_CFLAGS) $(EMU_CFLAGS) -I$(LFSDIR)/src $< -o $@

koreader-base.o koptcontext.o pdf.o: %.o: %.c
	$(CC) -c $(KOREADER_BASE_CFLAGS) $(K2PDFOPT_CFLAGS) $(EMU_CFLAGS) -I$(LFSDIR)/src $< -o $@

djvu.o: %.o: %.c
	$(CC) -c $(KOREADER_BASE_CFLAGS) $(K2PDFOPT_CFLAGS) -I$(DJVUDIR)/ $< -o $@

pic.o: %.o: %.c
	$(CC) -c $(KOREADER_BASE_CFLAGS) $< -o $@

pic_jpeg.o: %.o: %.c
	$(CC) -c $(KOREADER_BASE_CFLAGS) -I$(JPEGDIR)/ -I$(MUPDFDIR)/scripts/ $< -o $@

cre.o: %.o: %.cpp
	$(CC) -c $(CFLAGS) -I$(CRENGINEDIR)/crengine/include/ -I$(LUADIR)/src $< -o $@

lfs.o: $(LFSDIR)/src/lfs.c
	$(CC) -c $(CFLAGS) -I$(LUADIR)/src -I$(LFSDIR)/src $(LFSDIR)/src/lfs.c -o $@

fetchthirdparty:
	rm -rf mupdf/thirdparty
	test -d mupdf && (cd mupdf; git checkout .)  || echo warn: mupdf folder not found
	test -d $(LUADIR) && (cd $(LUADIR); git checkout .)  || echo warn: $(LUADIR) folder not found
	git submodule init
	git submodule update
	cd mupdf && (git submodule init; git submodule update)
	ln -sf kpvcrlib/crengine/cr3gui/data data
	test -e data/cr3.css || ln kpvcrlib/cr3.css data/
	test -d fonts || ln -sf $(TTF_FONTS_DIR) fonts
	test -d history || mkdir history
	test -d clipboard || mkdir clipboard
	# CREngine patch: disable fontconfig
	grep USE_FONTCONFIG $(CRENGINEDIR)/crengine/include/crsetup.h && grep -v USE_FONTCONFIG $(CRENGINEDIR)/crengine/include/crsetup.h > /tmp/new && mv /tmp/new $(CRENGINEDIR)/crengine/include/crsetup.h || echo "USE_FONTCONFIG already disabled"
	# CREngine patch: change child nodes' type face
	# @TODO replace this dirty hack  24.04 2012 (houqp)
	cd kpvcrlib/crengine/crengine/src && \
		patch -N -p0 < ../../../lvrend_node_type_face.patch && \
		patch -N -p3 < ../../../lvdocview-getCurrentPageLinks.patch || true
	# MuPDF patch: use external fonts
	cd mupdf && patch -N -p1 < ../mupdf.patch
	test -f popen-noshell/popen_noshell.c || svn co http://popen-noshell.googlecode.com/svn/trunk/ popen-noshell
	# popen_noshell patch: Make it build on recent TCs, and implement a simple Makefile for building it as a static lib
	cd popen-noshell && test -f Makefile || patch -N -p0 < popen_noshell-buildfix.patch

clean:
	rm -f *.o koreader-base slider_watcher extr emu_event

cleanthirdparty:
	rm -rf $(LIBDIR) ; mkdir $(LIBDIR)
	$(MAKE) -C $(LUADIR) CC="$(HOSTCC)" CFLAGS="$(BASE_CFLAGS)" clean
	$(MAKE) -C $(MUPDFDIR) build="release" clean
	$(MAKE) -C $(CRENGINEDIR)/thirdparty/antiword clean
	test -d $(CRENGINEDIR)/thirdparty/chmlib && $(MAKE) -C $(CRENGINEDIR)/thirdparty/chmlib clean || echo warn: chmlib folder not found
	test -d $(CRENGINEDIR)/thirdparty/libpng && ($(MAKE) -C $(CRENGINEDIR)/thirdparty/libpng clean) || echo warn: chmlib folder not found
	test -d $(CRENGINEDIR)/crengine && ($(MAKE) -C $(CRENGINEDIR)/crengine clean) || echo warn: chmlib folder not found
	test -d $(KPVCRLIBDIR) && ($(MAKE) -C $(KPVCRLIBDIR) clean) || echo warn: chmlib folder not found
	rm -rf $(DJVUDIR)/build
	$(MAKE) -C $(POPENNSDIR) clean
	$(MAKE) -C $(K2PDFOPTLIBDIR) clean

$(MUPDFLIBS) $(THIRDPARTYLIBS):
	# build only thirdparty libs, libfitz and pdf utils, which will care for libmupdf.a being built
ifdef EMULATE_READER
	$(MAKE) -C mupdf XCFLAGS="$(CFLAGS) -DNOBUILTINFONT" build="release" CC="$(CC)" MUPDF= MU_APPS= BUSY_APP= XPS_APPS= verbose=1 NOX11=yes
else
	# generate data headers
	$(MAKE) -C mupdf generate build="release"
	$(MAKE) -C mupdf XCFLAGS="$(CFLAGS) -DNOBUILTINFONT" build="release" CC="$(CC)" MUPDF= MU_APPS= BUSY_APP= XPS_APPS= verbose=1 NOX11=yes CROSSCOMPILE=yes OS=Kindle
endif

$(DJVULIBS):
	mkdir -p $(DJVUDIR)/build
ifdef EMULATE_READER
	cd $(DJVUDIR)/build && CC="$(HOSTCC)" CXX="$(HOSTCXX)" CFLAGS="$(HOSTCFLAGS)" CXXFLAGS="$(HOSTCFLAGS)" LDFLAGS="$(LDFLAGS)" ../configure --disable-desktopfiles --disable-static --enable-shared --disable-xmltools --disable-largefile
else
	cd $(DJVUDIR)/build && CC="$(CC)" CXX="$(CXX)" CFLAGS="$(CFLAGS)" CXXFLAGS="$(CXXFLAGS)" LDFLAGS="$(LDFLAGS)" ../configure --disable-desktopfiles --disable-static --enable-shared --host=$(CHOST) --disable-xmltools --disable-largefile
endif
	$(MAKE) -C $(DJVUDIR)/build
	test -d $(LIBDIR) || mkdir $(LIBDIR)
	cp -a $(DJVULIBDIR)/libdjvulibre.so* $(LIBDIR)

$(CRE_3RD_LIBS) $(CRELIB):
	cd $(KPVCRLIBDIR) && rm -rf CMakeCache.txt CMakeFiles && \
		CFLAGS="$(CFLAGS)" CXXFLAGS="$(CXXFLAGS)" CC="$(CC)" CXX="$(CXX)" LDFLAGS="$(LDFLAGS)" cmake -D CMAKE_BUILD_TYPE=Release . && \
		$(MAKE) VERBOSE=1
	test -d $(LIBDIR) || mkdir $(LIBDIR)
	cp -a $(KPVCRLIBDIR)/libcrengine.so $(CRELIB)

$(LUALIB):
ifdef EMULATE_READER
	$(MAKE) -C $(LUADIR) BUILDMODE=shared
else
	# To recap: build its TARGET_CC from CROSS+CC, so we need HOSTCC in CC. Build its HOST/TARGET_CFLAGS based on CFLAGS, so we need a neutral CFLAGS without arch
	$(MAKE) -C $(LUADIR) BUILDMODE=shared CC="$(HOSTCC)" HOST_CC="$(HOSTCC) -m32" CFLAGS="$(BASE_CFLAGS)" HOST_CFLAGS="$(HOSTCFLAGS)" TARGET_CFLAGS="$(CFLAGS)" CROSS="$(CHOST)-" TARGET_FLAGS="-DLUAJIT_NO_LOG2 -DLUAJIT_NO_EXP2"
endif
	test -d $(LIBDIR) || mkdir $(LIBDIR)
	cp -a $(LUADIR)/src/libluajit.so* $(LUALIB)
	ln -s libluajit-5.1.so.2 $(LIBDIR)/libluajit-5.1.so

$(POPENNSLIB):
	$(MAKE) -C $(POPENNSDIR) CC="$(CC)" AR="$(AR)"

$(K2PDFOPTLIB):
	$(MAKE) -C $(K2PDFOPTLIBDIR) BUILDMODE=shared CC="$(CC)" CFLAGS="$(CFLAGS) -O3" AR="$(AR)" all
	test -d $(LIBDIR) || mkdir $(LIBDIR)
	cp -a $(K2PDFOPTLIBDIR)/libk2pdfopt.so* $(LIBDIR)

thirdparty: $(MUPDFLIBS) $(THIRDPARTYLIBS) $(LUALIB) $(DJVULIBS) $(CRELIB) $(CRE_3RD_LIBS) $(POPENNSLIB) $(K2PDFOPTLIB)
