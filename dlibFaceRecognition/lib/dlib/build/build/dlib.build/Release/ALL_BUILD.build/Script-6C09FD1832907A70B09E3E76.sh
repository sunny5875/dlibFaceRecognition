#!/bin/sh
set -e
if test "$CONFIGURATION" = "Debug"; then :
  cd /Users/hyunsubin/faceRecognition/dlib-19.24/dlib/build
  echo Build\ all\ projects
fi
if test "$CONFIGURATION" = "Release"; then :
  cd /Users/hyunsubin/faceRecognition/dlib-19.24/dlib/build
  echo Build\ all\ projects
fi
if test "$CONFIGURATION" = "MinSizeRel"; then :
  cd /Users/hyunsubin/faceRecognition/dlib-19.24/dlib/build
  echo Build\ all\ projects
fi
if test "$CONFIGURATION" = "RelWithDebInfo"; then :
  cd /Users/hyunsubin/faceRecognition/dlib-19.24/dlib/build
  echo Build\ all\ projects
fi

