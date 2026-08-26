<!-- :shell>>> ~/core/codeBits/bin/emacs_package_com_to_md.rb mjr-flow.el -->
# Emacs Workflow

See the README: https://github.com/richmit/mjr-flow/

## Introduction

Over the years I have developed a workflow, or perhaps just a set of habits.  This package provides support for some of these habits.

So first, some things about the kinds of things I do with Emacs.  I use Emacs to write/build/debug a lot of code in a lot of different programming
languages for a lot of different platforms.  I use Emacs to interface with a number of scientific, mathematical, & engineering software packages -- both
for interactive problem solving and automation.  I also use Emacs to interact with external physical hardware like debug probes and electronic test
equipment.  I normally use a 43" screen with Emacs taking up 3/4 of it right in the center.

## `dired` & `eshell`

I make heavy use of `eshell` & `dired` and have extensively customized them both.  `mjr-dired-for-buffer` & `mjr-eshell` starts, or switches to, a
`dired`/`eshell` for the buffer I'm using.  They have some fancy rules for the directory in which to start those buffers.  For example if the file I'm working
on is part of a software development project, the eshell & `dired` will be started, or an existing one reused, in the project root directory with the `dired`
buffer getting the CWD inserted if it's missing.  

## Window Management

`dired` & `eshell` are not the only buffers that might be related to the buffer I'm working with.  For example a C++ source file might have an associated
compile buffer, or a Julia code buffer might have an associated interactive buffer.  `mjr-arrange-windows` is designed to collect together all of these
related buffers and display them in a sensible way in the frame.  It can have very sophisticated rules set up to identify related buffers and display them.
`mjr-window-zoom` allows me to zoom into, and out of, a buffer.  `mjr-follow-mode` takes over a frame creating follow-style windows.  The functions
`mjr-view-file-or-url-at-point` & `mjr-open-cwd` provide some welcome interaction with the host operating system -- these become more important because of
my use of `dired` buffers.  Some of these functions provide significantly more complex behavior that one might expect -- `mjr-eshell` &
`mjr-arrange-windows` in particular.

## My Keybindings

Because these tools form part of my day-to-day workflow, I bind most of them to keys in my init.el file -- they are not bound in this package. My
suggestions are:
     
  - C-c d `mjr-dired-for-buffer`
  - C-c s `mjr-eshell` 
  - C-c w `mjr-arrange-windows` 
  - C-c z `mjr-window-zoom`
  - C-c f `mjr-follow-mode`
  - C-c v `mjr-view-file-or-url-at-point`
  - C-c e `mjr-open-cwd`
  - C-c s `mjr-select-window`

## Installing

The easiest way to install mjr-eval is to pull it directly from github:

     (package-vc-install (list 'mjr-eval
                          :url "https://github.com/richmit/mjr-eval"
                          :rev 'newest))
