package org.streamroller;

import java.io.*;
import java.awt.*;
import java.awt.event.*;
import javax.swing.*;

public class MainUI {
  
  public static JTextArea textArea = new JTextArea();
  public static TrayIcon trayIcon;
  final JFrame frame;
  public static Image icon = new ImageIcon("public/icon.png").getImage();
  
  public MainUI(JFrame aframe) throws IOException {
    frame = aframe;
    
    MessageConsole mc = new MessageConsole(textArea);
    mc.redirectOut();
    mc.redirectErr();
    mc.setMessageLines(500);
    
    textArea.setEditable(false);
    textArea.setLineWrap(true);
    frame.getContentPane().add(new JScrollPane(textArea));
    
    frame.setIconImage(icon);
    frame.setSize(640,480);
    frame.setVisible(true);
    frame.setResizable(true);
    
    if (SystemTray.isSupported()) {
      SystemTray tray = SystemTray.getSystemTray();
  
      ActionListener exitListener = new ActionListener() {
          public void actionPerformed(ActionEvent e) {
              System.exit(0);
          }
      };
          
      ActionListener showListener = new ActionListener() {
          public void actionPerformed(ActionEvent e) {
              frame.show();
          }
      };

      MouseListener mouseListener = new MouseListener() {
        public void mouseEntered(MouseEvent e) {}
        public void mouseExited(MouseEvent e) {}
        public void mousePressed(MouseEvent e) {}
        public void mouseReleased(MouseEvent e) {}
        public void mouseClicked(MouseEvent e) {
          if (e.getButton() != MouseEvent.BUTTON1) { return; }
          if (frame.isVisible()) { frame.hide(); } else { frame.show(); }
        }
      };


      PopupMenu popup = new PopupMenu();
      MenuItem showItem = new MenuItem("Show Window");
      showItem.addActionListener(showListener);
      popup.add(showItem);
      MenuItem exitItem = new MenuItem("Exit");
      exitItem.addActionListener(exitListener);
      popup.add(exitItem);

      trayIcon = new TrayIcon(icon, "StreamRoller", popup);      
      trayIcon.setImageAutoSize(true);
      trayIcon.addMouseListener(mouseListener);
  
      try {
        frame.setDefaultCloseOperation(JFrame.HIDE_ON_CLOSE);
        tray.add(trayIcon);
      } catch (AWTException e) {
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        System.err.println("Unable to add tray icon.");
      }
    } else {
      frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
      System.out.println("System tray icon not supported by environment.");
    }
  }

}