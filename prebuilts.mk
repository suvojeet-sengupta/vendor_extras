PRODUCT_SOONG_NAMESPACES += vendor/extras
PRODUCT_SOONG_NAMESPACES += external/vanadium

ifeq ($(SGC),true)
PRODUCT_PACKAGES += \
    SGCam \
    privapp-permissions-SGCam
endif

ifeq ($(SUVM),true)
PRODUCT_PACKAGES += \
    SuvMusic
endif

ifeq ($(KSUN),true)
PRODUCT_PACKAGES += \
    KernelSU-Next
endif

ifeq ($(VND),true)
PRODUCT_PACKAGES += \
    TrichromeLibrary \
    TrichromeWebView \
    TrichromeChrome \
    VanadiumConfig
endif
