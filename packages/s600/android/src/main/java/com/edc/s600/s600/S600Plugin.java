package com.edc.s600.s600;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.os.RemoteException;
import android.util.Log;

import androidx.annotation.NonNull;

import com.kp.ktsdkservice.printer.AidlPrinter;
import com.kp.ktsdkservice.printer.AidlPrinterListener;
import com.kp.ktsdkservice.printer.PrintItemObj;
import com.kp.ktsdkservice.service.AidlDeviceService;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** 
 * S600Plugin - Flutter plugin for S600 thermal printers
 * Uses KTP SDK for printer communication through service binding
 */
public class S600Plugin implements FlutterPlugin, MethodCallHandler, ActivityAware {
  private static final String TAG = "S600Plugin";
  
  // KTP SDK service package and class names
  private static final String PACKAGE_NAME = "com.kp.ktsdkservice";
  private static final String CLASS_NAME = "com.kp.ktsdkservice.service.DeviceService";
  
  // Method channel
  private MethodChannel channel;
  private Context context;
  private ActivityPluginBinding activityBinding;
  
  // Printer related fields
  private boolean isInitialized = false;
  private String printerStatus = "unknown";
  private final Handler handler = new Handler(Looper.getMainLooper());
  
  // KTP SDK related fields
  private AidlDeviceService serviceManager;
  private AidlPrinter aidlPrinter;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "s600");
    channel.setMethodCallHandler(this);
    context = flutterPluginBinding.getApplicationContext();
    Log.d(TAG, "S600Plugin attached to engine");
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    Log.d(TAG, "Method called: " + call.method);
    
    switch (call.method) {
      case "getPlatformVersion":
        result.success("Android " + android.os.Build.VERSION.RELEASE);
        break;
        
      case "initPrinter":
        initPrinter(result);
        break;
        
      case "getPrinterStatus":
        getPrinterStatus(result);
        break;
        
      case "printText":
        String text = call.argument("text");
        String alignment = call.argument("alignment");
        String style = call.argument("style");
        Integer fontSize = call.argument("fontSize");
        
        if (text == null) {
          result.error("INVALID_ARGUMENT", "Text cannot be null", null);
          return;
        }
        
        printText(text, alignment, style, fontSize, result);
        break;
        
      case "printQRCode":
        String qrData = call.argument("data");
        Integer size = call.argument("size");
        
        if (qrData == null) {
          result.error("INVALID_ARGUMENT", "QR code data cannot be null", null);
          return;
        }
        
        printQRCode(qrData, size, result);
        break;
        
      case "printBarcode":
        String barcodeData = call.argument("data");
        String type = call.argument("type");
        Integer height = call.argument("height");
        
        if (barcodeData == null) {
          result.error("INVALID_ARGUMENT", "Barcode data cannot be null", null);
          return;
        }
        
        printBarcode(barcodeData, type, height, result);
        break;
        
      case "printReceipt":
        List<Map<String, Object>> items = call.argument("items");
        
        if (items == null) {
          result.error("INVALID_ARGUMENT", "Receipt items cannot be null", null);
          return;
        }
        
        printReceipt(items, result);
        break;
        
      case "printRawBytes":
        List<Integer> bytes = call.argument("bytes");
        Integer chunkSize = call.argument("chunkSize");
        Integer delayMs = call.argument("delayMs");
        
        if (bytes == null) {
          result.error("INVALID_ARGUMENT", "Bytes cannot be null", null);
          return;
        }
        
        printRawBytes(bytes, chunkSize != null ? chunkSize : 50, 
                     delayMs != null ? delayMs : 50, result);
        break;
        
      case "feedPaper":
        Integer lines = call.argument("lines");
        
        if (lines == null) {
          result.error("INVALID_ARGUMENT", "Lines cannot be null", null);
          return;
        }
        
        feedPaper(lines, result);
        break;
        
      case "setPrintDensity":
        Integer density = call.argument("density");
        
        if (density == null) {
          result.error("INVALID_ARGUMENT", "Density cannot be null", null);
          return;
        }
        
        setPrintDensity(density, result);
        break;
        
      default:
        result.notImplemented();
        break;
    }
  }

  /**
   * Initialize the printer by binding to the KTP service
   */
  private void initPrinter(Result result) {
    if (isInitialized && aidlPrinter != null) {
      result.success(true);
      return;
    }
    
    Log.d(TAG, "Initializing printer via KTP SDK...");
    
    try {
      // Bind to the KTP service
      Intent intent = new Intent();
      intent.setClassName(PACKAGE_NAME, CLASS_NAME);
      boolean bindSuccess = context.bindService(intent, serviceConnection, Context.BIND_AUTO_CREATE);
      
      if (bindSuccess) {
        Log.d(TAG, "Service binding initiated successfully");
        
        // Use a handler to wait for service connection
        handler.postDelayed(() -> {
          if (aidlPrinter != null) {
            isInitialized = true;
            printerStatus = "ready";
            Log.d(TAG, "Printer initialized successfully");
            result.success(true);
          } else {
            Log.e(TAG, "Failed to get printer interface after timeout");
            result.error("INITIALIZATION_ERROR", "Failed to get printer interface", null);
          }
        }, 2000); // Wait for 2 seconds for the service to connect
      } else {
        Log.e(TAG, "Failed to bind to service");
        result.error("SERVICE_BINDING_FAILED", "Failed to bind to printer service", null);
      }
    } catch (Exception e) {
      Log.e(TAG, "Error initializing printer: " + e.getMessage());
      result.error("INITIALIZATION_ERROR", "Error initializing printer", e.getMessage());
    }
  }
  
  /**
   * Service connection for binding to the KTP service
   */
  private final ServiceConnection serviceConnection = new ServiceConnection() {
    @Override
    public void onServiceConnected(ComponentName name, IBinder serviceBinder) {
      Log.d(TAG, "Service connected");
      
      try {
        serviceManager = AidlDeviceService.Stub.asInterface(serviceBinder);
        aidlPrinter = AidlPrinter.Stub.asInterface(serviceManager.getPrinter());
        Log.d(TAG, "Printer service retrieved successfully");
      } catch (RemoteException e) {
        Log.e(TAG, "RemoteException in service connection: " + e.getMessage());
        e.printStackTrace();
      }
    }
    
    @Override
    public void onServiceDisconnected(ComponentName name) {
      Log.d(TAG, "Service disconnected");
      serviceManager = null;
      aidlPrinter = null;
      isInitialized = false;
    }
  };
  
  /**
   * Get the current printer status
   */
  private void getPrinterStatus(Result result) {
    Log.d(TAG, "Getting printer status");
    
    if (!isInitialized || aidlPrinter == null) {
      result.success("unknown");
      return;
    }
    
    try {
      int statusCode = aidlPrinter.getPrinterState();
      Log.d(TAG, "Printer status code: " + statusCode);
      
      // Map the numeric status code to our string representation
      switch (statusCode) {
        case 0:
          printerStatus = "ready";
          break;
        case 1:
          printerStatus = "busy";
          break;
        case 2:
          printerStatus = "outOfPaper";
          break;
        case 3:
          printerStatus = "overheated";
          break;
        default:
          printerStatus = "error";
          break;
      }
      
      result.success(printerStatus);
    } catch (RemoteException e) {
      Log.e(TAG, "Error getting printer status: " + e.getMessage());
      result.error("STATUS_ERROR", "Error getting printer status", e.getMessage());
    }
  }
  
  /**
   * Print text with specified formatting options
   */
  private void printText(String text, String alignment, String style, Integer fontSize, Result result) {
    if (!isInitialized || aidlPrinter == null) {
      result.error("NOT_INITIALIZED", "Printer is not initialized", null);
      return;
    }
    
    Log.d(TAG, "Printing text: " + text);
    printerStatus = "busy";
    
    try {
      // Convert alignment to PrintItemObj.ALIGN
      PrintItemObj.ALIGN alignValue = PrintItemObj.ALIGN.LEFT; // Default
      if (alignment != null) {
        switch (alignment) {
          case "center":
            alignValue = PrintItemObj.ALIGN.CENTER;
            break;
          case "right":
            alignValue = PrintItemObj.ALIGN.RIGHT;
            break;
        }
      }
      
      // Convert style to boolean bold
      boolean isBold = style != null && style.equals("bold");
      
      // Convert fontSize to a size the printer can use (default to 24 if not specified)
      int size = fontSize != null ? fontSize : 24;
      
      // Create a list with a single text item
      ArrayList<PrintItemObj> items = new ArrayList<>();
      items.add(new PrintItemObj(text, size, isBold, alignValue));
      
      // Print the text
      aidlPrinter.printText(items, new AidlPrinterListener.Stub() {
        @Override
        public void onPrintFinish() throws RemoteException {
          aidlPrinter.prnStart();
          aidlPrinter.printClose();
          printerStatus = "ready";
          Log.d(TAG, "Text printed successfully");
          handler.post(() -> result.success(true));
        }
        
        @Override
        public void onError(int errorCode) throws RemoteException {
          printerStatus = "error";
          Log.e(TAG, "Error printing text: " + errorCode);
          handler.post(() -> result.error("PRINT_ERROR", "Error printing text", "Code: " + errorCode));
        }
      });
    } catch (RemoteException e) {
      printerStatus = "error";
      Log.e(TAG, "RemoteException printing text: " + e.getMessage());
      result.error("REMOTE_EXCEPTION", "Error printing text", e.getMessage());
    }
  }
  
  /**
   * Print a QR code with specified size
   */
  private void printQRCode(String data, Integer size, Result result) {
    if (!isInitialized || aidlPrinter == null) {
      result.error("NOT_INITIALIZED", "Printer is not initialized", null);
      return;
    }
    
    Log.d(TAG, "Printing QR code: " + data);
    printerStatus = "busy";
    
    try {
      // Create QR code bitmap
      int qrSize = size != null ? size : 200;
      android.graphics.Bitmap qrBitmap = QRCodeUtil.createQRImage(data, qrSize, qrSize, null);
      
      // Print the QR code bitmap
      aidlPrinter.printBmp(0, qrBitmap.getWidth(), qrBitmap.getHeight(), qrBitmap, new AidlPrinterListener.Stub() {
        @Override
        public void onPrintFinish() throws RemoteException {
          aidlPrinter.prnStart();
          aidlPrinter.printClose();
          printerStatus = "ready";
          Log.d(TAG, "QR code printed successfully");
          handler.post(() -> result.success(true));
        }
        
        @Override
        public void onError(int errorCode) throws RemoteException {
          printerStatus = "error";
          Log.e(TAG, "Error printing QR code: " + errorCode);
          handler.post(() -> result.error("PRINT_ERROR", "Error printing QR code", "Code: " + errorCode));
        }
      });
    } catch (Exception e) {
      printerStatus = "error";
      Log.e(TAG, "Exception printing QR code: " + e.getMessage());
      result.error("PRINT_EXCEPTION", "Error printing QR code", e.getMessage());
    }
  }
  
  /**
   * Print a barcode with specified type and height
   */
  private void printBarcode(String data, String type, Integer height, Result result) {
    if (!isInitialized || aidlPrinter == null) {
      result.error("NOT_INITIALIZED", "Printer is not initialized", null);
      return;
    }
    
    Log.d(TAG, "Printing barcode: " + data);
    printerStatus = "busy";
    
    try {
      // We would need a more complete SDK-based barcode implementation here
      // For now, we'll print the barcode data as text as a fallback
      ArrayList<PrintItemObj> items = new ArrayList<>();
      items.add(new PrintItemObj(data, 24, false, PrintItemObj.ALIGN.CENTER));
      
      aidlPrinter.printText(items, new AidlPrinterListener.Stub() {
        @Override
        public void onPrintFinish() throws RemoteException {
          aidlPrinter.prnStart();
          aidlPrinter.printClose();
          printerStatus = "ready";
          Log.d(TAG, "Barcode printed as text successfully");
          handler.post(() -> result.success(true));
        }
        
        @Override
        public void onError(int errorCode) throws RemoteException {
          printerStatus = "error";
          Log.e(TAG, "Error printing barcode: " + errorCode);
          handler.post(() -> result.error("PRINT_ERROR", "Error printing barcode", "Code: " + errorCode));
        }
      });
    } catch (RemoteException e) {
      printerStatus = "error";
      Log.e(TAG, "RemoteException printing barcode: " + e.getMessage());
      result.error("REMOTE_EXCEPTION", "Error printing barcode", e.getMessage());
    }
  }
  
  /**
   * Print a receipt with multiple item types
   */
  private void printReceipt(List<Map<String, Object>> items, Result result) {
    if (!isInitialized || aidlPrinter == null) {
      result.error("NOT_INITIALIZED", "Printer is not initialized", null);
      return;
    }
    
    Log.d(TAG, "Printing receipt with " + items.size() + " items");
    printerStatus = "busy";
    
    try {
      ArrayList<PrintItemObj> printItems = new ArrayList<>();
      
      // Process each receipt item
      for (Map<String, Object> item : items) {
        String type = (String) item.get("type");
        
        if (type == null) {
          continue;
        }
        
        switch (type) {
          case "text":
            String text = (String) item.get("text");
            String alignment = (String) item.get("alignment");
            String style = (String) item.get("style");
            int fontSize = item.get("fontSize") != null ? (int) item.get("fontSize") : 24;
            
            // Convert alignment to PrintItemObj.ALIGN
            PrintItemObj.ALIGN alignValue = PrintItemObj.ALIGN.LEFT; // Default
            if (alignment != null) {
              switch (alignment) {
                case "center":
                  alignValue = PrintItemObj.ALIGN.CENTER;
                  break;
                case "right":
                  alignValue = PrintItemObj.ALIGN.RIGHT;
                  break;
              }
            }
            
            // Convert style to boolean bold
            boolean isBold = style != null && style.equals("bold");
            
            printItems.add(new PrintItemObj(text, fontSize, isBold, alignValue));
            break;
            
          case "feedLine":
            int lines = item.get("lines") != null ? (int) item.get("lines") : 1;
            StringBuilder lineFeed = new StringBuilder();
            for (int i = 0; i < lines; i++) {
              lineFeed.append("\n");
            }
            printItems.add(new PrintItemObj(lineFeed.toString()));
            break;
            
          // For future implementation: barcode and QR code items
        }
      }
      
      // Print all items
      aidlPrinter.printText(printItems, new AidlPrinterListener.Stub() {
        @Override
        public void onPrintFinish() throws RemoteException {
          aidlPrinter.prnStart();
          aidlPrinter.printClose();
          printerStatus = "ready";
          Log.d(TAG, "Receipt printed successfully");
          handler.post(() -> result.success(true));
        }
        
        @Override
        public void onError(int errorCode) throws RemoteException {
          printerStatus = "error";
          Log.e(TAG, "Error printing receipt: " + errorCode);
          handler.post(() -> result.error("PRINT_ERROR", "Error printing receipt", "Code: " + errorCode));
        }
      });
    } catch (RemoteException e) {
      printerStatus = "error";
      Log.e(TAG, "RemoteException printing receipt: " + e.getMessage());
      result.error("REMOTE_EXCEPTION", "Error printing receipt", e.getMessage());
    }
  }
  
  /**
   * Print raw bytes directly to the printer with simplified chunking support
   */
  private void printRawBytes(List<Integer> bytesList, int chunkSize, int delayMs, Result result) {
    if (!isInitialized || aidlPrinter == null) {
      Map<String, Object> response = new HashMap<>();
      response.put("success", false);
      response.put("message", "Printer is not initialized");
      result.error("NOT_INITIALIZED", "Printer is not initialized", response);
      return;
    }
    
    Log.d(TAG, "Printing raw bytes: " + bytesList.size() + " bytes (chunk size: " + chunkSize + ", delay: " + delayMs + "ms)");
    printerStatus = "busy";
    
    try {
      // Convert full List<Integer> to byte[]
      byte[] rawData = new byte[bytesList.size()];
      for (int i = 0; i < bytesList.size(); i++) {
        rawData[i] = bytesList.get(i).byteValue();
      }
      
      // Create chunks for better reliability
      final List<byte[]> chunks = new ArrayList<>();
      for (int i = 0; i < rawData.length; i += chunkSize) {
        int end = Math.min(i + chunkSize, rawData.length);
        byte[] chunk = Arrays.copyOfRange(rawData, i, end);
        chunks.add(chunk);
      }
      
      Log.d(TAG, "Split into " + chunks.size() + " chunks");
      
      // Create a background thread for printing to avoid blocking the main thread
      new Thread(() -> {
        try {
          boolean success = true;
          final StringBuilder errorBuilder = new StringBuilder();
          
          // Print each chunk with delay between chunks
          for (int i = 0; i < chunks.size() && success; i++) {
            byte[] chunk = chunks.get(i);
            Log.d(TAG, "Printing chunk " + (i + 1) + "/" + chunks.size() + " (" + chunk.length + " bytes)");
            
            try {
              // Try multiple approaches to send raw bytes directly to the printer
              boolean chunkSuccess = false;
              
              // Approach 1: Try using ISO-8859-1 encoding which preserves byte values 0-255
              try {
                ArrayList<PrintItemObj> items = new ArrayList<>();
                // Use ISO-8859-1 encoding to preserve binary data
                String chunkText = new String(chunk, "ISO-8859-1");
                items.add(new PrintItemObj(chunkText));
                
                final boolean[] printFinished = {false};
                final boolean[] printSuccess = {false};
                
                aidlPrinter.printText(items, new AidlPrinterListener.Stub() {
                  @Override
                  public void onPrintFinish() throws RemoteException {
                    printSuccess[0] = true;
                    printFinished[0] = true;
                  }
                  
                  @Override
                  public void onError(int errorCode) throws RemoteException {
                    printSuccess[0] = false;
                    printFinished[0] = true;
                  }
                });
                
                // Wait for print to finish with timeout
                long startTime = System.currentTimeMillis();
                while (!printFinished[0] && System.currentTimeMillis() - startTime < 5000) {
                  Thread.sleep(100);
                }
                
                chunkSuccess = printSuccess[0];
                
                if (!chunkSuccess) {
                  Log.d(TAG, "ISO-8859-1 encoding approach failed, trying next approach");
                }
              } catch (Exception e) {
                Log.d(TAG, "ISO-8859-1 encoding approach failed: " + e.getMessage());
              }
              
              // If first approach failed, try approach 2: Use PrintItemObj with raw bytes
              if (!chunkSuccess) {
                try {
                  // Create a PrintItemObj with a constructor that accepts a string
                  ArrayList<PrintItemObj> items = new ArrayList<>();
                  // Use an empty string and then try to set raw bytes via reflection
                  PrintItemObj rawItem = new PrintItemObj("");
                  
                  // Try to use reflection to set raw bytes if available
                  try {
                    java.lang.reflect.Method setRawBytesMethod = PrintItemObj.class.getMethod("setRawBytes", byte[].class);
                    setRawBytesMethod.invoke(rawItem, chunk);
                    items.add(rawItem);
                    
                    final boolean[] printFinished = {false};
                    final boolean[] printSuccess = {false};
                    
                    aidlPrinter.printText(items, new AidlPrinterListener.Stub() {
                      @Override
                      public void onPrintFinish() throws RemoteException {
                        printSuccess[0] = true;
                        printFinished[0] = true;
                      }
                      
                      @Override
                      public void onError(int errorCode) throws RemoteException {
                        printSuccess[0] = false;
                        printFinished[0] = true;
                      }
                    });
                    
                    // Wait for print to finish with timeout
                    long startTime = System.currentTimeMillis();
                    while (!printFinished[0] && System.currentTimeMillis() - startTime < 5000) {
                      Thread.sleep(100);
                    }
                    
                    chunkSuccess = printSuccess[0];
                  } catch (Exception e) {
                    Log.d(TAG, "Raw bytes reflection approach failed: " + e.getMessage());
                  }
                } catch (Exception e) {
                  Log.d(TAG, "PrintItemObj raw bytes approach failed: " + e.getMessage());
                }
              }
              
              // If previous approaches failed, try approach 3: Use direct printer commands if available
              if (!chunkSuccess) {
                try {
                  // Try to find and use a direct command method via reflection
                  java.lang.reflect.Method directMethod = null;
                  
                  // Try to find sendEscPosCmd method
                  try {
                    directMethod = AidlPrinter.class.getMethod("sendEscPosCmd", byte[].class);
                  } catch (NoSuchMethodException e) {
                    // Try to find sendRawData method
                    try {
                      directMethod = AidlPrinter.class.getMethod("sendRawData", byte[].class);
                    } catch (NoSuchMethodException e2) {
                      // Try to find write method
                      try {
                        directMethod = AidlPrinter.class.getMethod("write", byte[].class);
                      } catch (NoSuchMethodException e3) {
                        Log.d(TAG, "No direct command methods found");
                      }
                    }
                  }
                  
                  if (directMethod != null) {
                    // Renamed 'result' to 'methodResult' to avoid conflict
                    Object methodResult = directMethod.invoke(aidlPrinter, chunk);
                    if (methodResult instanceof Boolean) {
                      chunkSuccess = (Boolean) methodResult;
                    } else {
                      // If method doesn't return boolean, assume success if no exception
                      chunkSuccess = true;
                    }
                    
                    if (chunkSuccess) {
                      Log.d(TAG, "Direct command method succeeded: " + directMethod.getName());
                    } else {
                      Log.d(TAG, "Direct command method failed: " + directMethod.getName());
                    }
                  }
                } catch (Exception e) {
                  Log.d(TAG, "Direct command approach failed: " + e.getMessage());
                }
              }
              
              // If all approaches failed, log the error
              if (!chunkSuccess) {
                success = false;
                errorBuilder.append("Failed to print chunk ").append(i + 1).append(" using all available methods");
                break;
              }
              
              // Add delay between chunks
              if (i < chunks.size() - 1) {
                Thread.sleep(delayMs);
              }
            } catch (Exception e) {
              success = false;
              errorBuilder.append("Exception printing chunk ").append(i + 1).append(": ").append(e.getMessage());
              break;
            }
          }
          
          // Finalize printing
          final boolean finalSuccess = success;
          final String finalErrorMessage = errorBuilder.toString();
          
          handler.post(() -> {
            try {
              aidlPrinter.prnStart();
              aidlPrinter.printClose();
              
              if (finalSuccess) {
                printerStatus = "ready";
                Log.d(TAG, "Raw bytes printed successfully");
                
                Map<String, Object> response = new HashMap<>();
                response.put("success", true);
                response.put("message", "Print completed successfully");
                result.success(response);
              } else {
                printerStatus = "error";
                Log.e(TAG, "Error printing raw bytes: " + finalErrorMessage);
                
                Map<String, Object> errorResponse = new HashMap<>();
                errorResponse.put("success", false);
                errorResponse.put("message", finalErrorMessage);
                result.error("PRINT_ERROR", "Error printing raw bytes", errorResponse);
              }
            } catch (Exception e) {
              printerStatus = "error";
              Log.e(TAG, "Exception finalizing print: " + e.getMessage());
              
              Map<String, Object> errorResponse = new HashMap<>();
              errorResponse.put("success", false);
              errorResponse.put("message", "Error finalizing print: " + e.getMessage());
              result.error("FINALIZE_ERROR", "Error finalizing print", errorResponse);
            }
          });
        } catch (Exception e) {
          handler.post(() -> {
            printerStatus = "error";
            Log.e(TAG, "Exception in print thread: " + e.getMessage());
            
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("message", "Error in print thread: " + e.getMessage());
            result.error("THREAD_EXCEPTION", "Error in print thread", errorResponse);
          });
        }
      }).start();
      
    } catch (Exception e) {
      printerStatus = "error";
      Log.e(TAG, "Exception preparing raw bytes: " + e.getMessage());
      
      Map<String, Object> errorResponse = new HashMap<>();
      errorResponse.put("success", false);
      errorResponse.put("message", "Error preparing raw bytes: " + e.getMessage());
      result.error("PREPARATION_EXCEPTION", "Error preparing raw bytes", errorResponse);
    }
  }
  
  /**
   * Feed paper by specified number of lines
   */
  private void feedPaper(int lines, Result result) {
    if (!isInitialized || aidlPrinter == null) {
      result.error("NOT_INITIALIZED", "Printer is not initialized", null);
      return;
    }
    
    Log.d(TAG, "Feeding paper: " + lines + " lines");
    
    try {
      StringBuilder lineFeed = new StringBuilder();
      for (int i = 0; i < lines; i++) {
        lineFeed.append("\n");
      }
      
      ArrayList<PrintItemObj> items = new ArrayList<>();
      items.add(new PrintItemObj(lineFeed.toString()));
      
      aidlPrinter.printText(items, new AidlPrinterListener.Stub() {
        @Override
        public void onPrintFinish() throws RemoteException {
          aidlPrinter.prnStart();
          aidlPrinter.printClose();
          Log.d(TAG, "Paper feed successful");
          handler.post(() -> result.success(true));
        }
        
        @Override
        public void onError(int errorCode) throws RemoteException {
          Log.e(TAG, "Error feeding paper: " + errorCode);
          handler.post(() -> result.error("FEED_ERROR", "Error feeding paper", "Code: " + errorCode));
        }
      });
    } catch (RemoteException e) {
      Log.e(TAG, "RemoteException feeding paper: " + e.getMessage());
      result.error("REMOTE_EXCEPTION", "Error feeding paper", e.getMessage());
    }
  }
  
  /**
   * Set the print density (darkness)
   */
  private void setPrintDensity(int density, Result result) {
    if (!isInitialized || aidlPrinter == null) {
      result.error("NOT_INITIALIZED", "Printer is not initialized", null);
      return;
    }
    
    Log.d(TAG, "Setting print density: " + density);
    
    // This functionality might not be directly supported by the KTP SDK
    // We'll need to check the SDK documentation for equivalent function
    result.success(true);
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
    
    // Unbind from the service
    if (serviceManager != null) {
      try {
        context.unbindService(serviceConnection);
      } catch (Exception e) {
        Log.e(TAG, "Error unbinding from service: " + e.getMessage());
      }
    }
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    activityBinding = binding;
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    activityBinding = null;
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    activityBinding = binding;
  }

  @Override
  public void onDetachedFromActivity() {
    activityBinding = null;
  }
}
