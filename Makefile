ARCHS = arm64 arm64e
TARGET := iphone:clang:latest:14.0

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NoCapCutNotifications
NoCapCutNotifications_FILES = Tweak.x
NoCapCutNotifications_CFLAGS = -fobjc-arc
NoCapCutNotifications_LAYOUT = layout

include $(THEOS_MAKE_PATH)/tweak.mk
