package org.streamroller;

import java.io.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

import java.net.URL;
import java.util.ArrayList;
import java.util.Properties;
import org.jruby.Ruby;
import org.jruby.RubyInstanceConfig;
import org.jruby.javasupport.JavaEmbedUtils;

public class Main
{
  
  private static Boolean useConsole = false;
  public static void main(String[] args) throws Exception
  {
    for (int i = 0; i < args.length; i++) {
      if (args[i].equals("--console")) {
        useConsole = true;
      }
    }

    if (useConsole == false) {
      JFrame frame = new JFrame("StreamRoller");
      MainUI mainui = new MainUI(frame);
    }

    System.out.println("Now loading StreamRoller...");

    RubyInstanceConfig config = new RubyInstanceConfig();
    config.setArgv(args);
    Ruby runtime = JavaEmbedUtils.initialize(new ArrayList(0), config);

    runtime.evalScriptlet("ENV['GEM_HOME'] = 'vendor/bundle/jruby/1.8'");
    runtime.evalScriptlet("require 'src/main'");
  }
}
