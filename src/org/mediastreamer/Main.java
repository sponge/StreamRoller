package org.mediastreamer;

import java.io.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

import java.net.URL;
import java.util.ArrayList;
import java.util.Properties;
import java.util.logging.LogManager;
import org.jruby.Ruby;
import org.jruby.RubyInstanceConfig;
import org.jruby.javasupport.JavaEmbedUtils;

public class Main
{

  public static JTextArea textArea = new JTextArea();
  private static Boolean useConsole = false;
  public static void main(String[] args) throws Exception
  {
    
    LogManager.getLogManager().readConfiguration(new StringBufferInputStream("org.jaudiotagger.level = OFF"));    
    
    for (int i = 0; i < args.length; i++) {
      if (args[i].equals("--console")) {
        useConsole = true;
      }
    }

    if (useConsole == false) {
      JFrame frame = new JFrame("MediaStreamer");
      
      textArea.setEditable(false);
      textArea.setLineWrap(true);
      frame.getContentPane().add(textArea);
      
      frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
      frame.setSize(640,480);
      frame.setVisible(true);
      frame.setResizable(true);
      
      new Console(textArea);
      
      if (SystemTray.isSupported()) {
        System.out.println("can init system tray");
      } else {
        System.out.println("System tray icon not supported by environment.");
      }
    }
    
    System.out.println("Now loading MediaStreamer");
    RubyInstanceConfig config = new RubyInstanceConfig();
    config.setArgv(args);
    Ruby runtime = JavaEmbedUtils.initialize(new ArrayList(0), config);
    String mainRubyFile = "main";
   
    ArrayList<String> config_data = new ArrayList<String>();
    try{
      java.io.InputStream ins = Main.class.getClassLoader().getResourceAsStream("run_configuration");
      if (ins == null ) {
        System.err.println("Did not find configuration file 'run_configuration', using defaults.");
      } else {
        config_data = getConfigFileContents(ins);
      }
    }
    catch(IOException ioe)
    {
      System.err.println("Error loading run configuration file 'run_configuration', using defaults: " + ioe);
    }
    catch(java.lang.NullPointerException npe)
    {
      System.err.println("Error loading run configuration file 'run_configuration', using defaults: " + npe );
    }

    for(String line : config_data) {
        String[] parts = line.split(":");
        if("main_ruby_file".equals(parts[0].replaceAll(" ", ""))) {
            mainRubyFile = parts[1].replaceAll(" ", "");
        }
    }

    runtime.evalScriptlet("require '" + mainRubyFile + "'");
  }

  public static URL getResource(String path) {
      return Main.class.getClassLoader().getResource(path);
  }
  
  private static ArrayList<String> getConfigFileContents(InputStream input) throws IOException, java.lang.NullPointerException {
    BufferedReader reader = new BufferedReader(new InputStreamReader(input));
    String line;
    ArrayList<String> contents = new ArrayList<String>();

    while ((line = reader.readLine()) != null) {
      contents.add(line);
    }
    reader.close();
    return(contents);
  }
}
