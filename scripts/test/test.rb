#!/usr/bin/env ruby
$:.unshift File.join(File.dirname(__FILE__), "..", "test")
require 'test_synchronization'
require 'test_indexers'
require 'test_analyzer'
require 'test_options'
require 'test_web'
require 'test_purge'
