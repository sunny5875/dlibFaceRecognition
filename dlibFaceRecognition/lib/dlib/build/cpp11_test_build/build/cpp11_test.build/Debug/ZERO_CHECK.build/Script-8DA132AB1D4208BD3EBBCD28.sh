#!/bin/sh
set -e
if test "$CONFIGURATION" = "Debug"; then :
  cd /Users/hyunsubin/faceRecognition/dlib-19.24/dlib/build/cpp11_test_build
  make -f /Users/hyunsubin/faceRecognition/dlib-19.24/dlib/build/cpp11_test_build/CMakeScripts/ReRunCMake.make
fi
if test "$CONFIGURATION" = "Release"; then :
  cd /Users/hyunsubin/faceRecognition/dlib-19.24/dlib/build/cpp11_test_build
  make -f /Users/hyunsubin/faceRecognition/dlib-19.24/dlib/build/cpp11_test_build/CMakeScripts/ReRunCMake.make
fi
if test "$CONFIGURATION" = "MinSizeRel"; then :
  cd /Users/hyunsubin/faceRecognition/dlib-19.24/dlib/build/cpp11_test_build
  make -f /Users/hyunsubin/faceRecognition/dlib-19.24/dlib/build/cpp11_test_build/CMakeScripts/ReRunCMake.make
fi
if test "$CONFIGURATION" = "RelWithDebInfo"; then :
  cd /Users/hyunsubin/faceRecognition/dlib-19.24/dlib/build/cpp11_test_build
  make -f /Users/hyunsubin/faceRecognition/dlib-19.24/dlib/build/cpp11_test_build/CMakeScripts/ReRunCMake.make
fi

