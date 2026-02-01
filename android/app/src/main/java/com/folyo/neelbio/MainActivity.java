package com.folyo.neelbio;

import android.os.Environment;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.folyo.neelbio/resume";

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            if (call.method.equals("downloadResume")) {
                                downloadResume(result);
                            } else if (call.method.equals("openDownloads")) {
                                openDownloads();
                                result.success(null);
                            } else if (call.method.equals("openResume")) {
                                String fileNameOrPath = call.arguments != null ? call.arguments.toString() : null;
                                openResume(fileNameOrPath);
                                result.success(null);
                            } else {
                                result.notImplemented();
                            }
                        }
                );
    }

    private void downloadResume(MethodChannel.Result result) {
        new Thread(() -> {
            try {
                // Get the asset manager
                InputStream inputStream = getAssets().open("flutter_assets/assets/resume/Neel_Modi_Resume.pdf");

                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
                    // For Android 10 (API 29) and above, use MediaStore
                    android.content.ContentValues values = new android.content.ContentValues();
                    values.put(android.provider.MediaStore.MediaColumns.DISPLAY_NAME, "Neel_Modi_Resume.pdf");
                    values.put(android.provider.MediaStore.MediaColumns.MIME_TYPE, "application/pdf");
                    values.put(android.provider.MediaStore.MediaColumns.RELATIVE_PATH, android.os.Environment.DIRECTORY_DOWNLOADS);

                    android.net.Uri uri = getContentResolver().insert(android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, values);

                    if (uri != null) {
                        try (java.io.OutputStream outputStream = getContentResolver().openOutputStream(uri)) {
                            if (outputStream != null) {
                                byte[] buffer = new byte[1024];
                                int length;
                                while ((length = inputStream.read(buffer)) > 0) {
                                    outputStream.write(buffer, 0, length);
                                }
                                
                                // Fetch the actual display name that was assigned (in case of duplicates)
                                String actualDisplayName = "Neel_Modi_Resume.pdf"; // Default
                                android.database.Cursor cursor = getContentResolver().query(uri, new String[]{android.provider.MediaStore.MediaColumns.DISPLAY_NAME}, null, null, null);
                                if (cursor != null && cursor.moveToFirst()) {
                                    actualDisplayName = cursor.getString(cursor.getColumnIndexOrThrow(android.provider.MediaStore.MediaColumns.DISPLAY_NAME));
                                    cursor.close();
                                }

                                final String finalDisplayName = actualDisplayName;
                                runOnUiThread(() -> result.success(finalDisplayName));
                            } else {
                                runOnUiThread(() -> result.error("IO_ERROR", "Failed to open output stream", null));
                            }
                        } catch (IOException e) {
                             runOnUiThread(() -> result.error("IO_ERROR", "Failed to write resume: " + e.getMessage(), null));
                        }
                    } else {
                         runOnUiThread(() -> result.error("IO_ERROR", "Failed to create MediaStore entry", null));
                    }
                } else {
                    // For older Android versions, use the File API
                    File downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS);
                    if (!downloadsDir.exists()) {
                         downloadsDir.mkdirs();
                    }
                    File file = new File(downloadsDir, "Neel_Modi_Resume.pdf");

                    FileOutputStream outputStream = new FileOutputStream(file);
                    byte[] buffer = new byte[1024];
                    int length;
                    while ((length = inputStream.read(buffer)) > 0) {
                        outputStream.write(buffer, 0, length);
                    }
                    outputStream.close();
                    runOnUiThread(() -> result.success(file.getAbsolutePath()));
                }
                inputStream.close();

            } catch (IOException e) {
                 runOnUiThread(() -> result.error("IO_ERROR", "Failed to help download resume: " + e.getMessage(), null));
            }
        }).start();
    }

    private void openDownloads() {
        android.content.Intent intent = new android.content.Intent(android.app.DownloadManager.ACTION_VIEW_DOWNLOADS);
        intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(intent);
    }

    private void openResume(String fileNameOrPath) {
        if (fileNameOrPath == null) {
             android.widget.Toast.makeText(this, "Resume path missing", android.widget.Toast.LENGTH_SHORT).show();
             return;
        }

        if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.Q) {
            // For Android 10 (API 29) and above, use MediaStore to find the file by Display Name
             android.database.Cursor cursor = getContentResolver().query(
                android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI,
                new String[]{android.provider.MediaStore.MediaColumns._ID},
                android.provider.MediaStore.MediaColumns.DISPLAY_NAME + "=?",
                new String[]{fileNameOrPath},
                null
            );

            // If not found by exact name, try sorting by date added to find the latest with similar name?
            // But since we returned the EXACT name from downloadResume, this query should work.
            if (cursor != null && cursor.moveToFirst()) {
                long id = cursor.getLong(cursor.getColumnIndexOrThrow(android.provider.MediaStore.MediaColumns._ID));
                android.net.Uri uri = android.content.ContentUris.withAppendedId(android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI, id);
                cursor.close();

                android.content.Intent intent = new android.content.Intent(android.content.Intent.ACTION_VIEW);
                intent.setDataAndType(uri, "application/pdf");
                intent.addFlags(android.content.Intent.FLAG_GRANT_READ_URI_PERMISSION);
                intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK);
                
                try {
                     startActivity(intent);
                } catch (android.content.ActivityNotFoundException e) {
                     android.widget.Toast.makeText(this, "No PDF viewer found", android.widget.Toast.LENGTH_SHORT).show();
                }
            } else {
                 if (cursor != null) cursor.close();
                 android.widget.Toast.makeText(this, "Resume not found: " + fileNameOrPath, android.widget.Toast.LENGTH_SHORT).show();
            }

        } else {
             // For older Android versions, fileNameOrPath is the absolute path
            File file = new File(fileNameOrPath);

            if (file.exists()) {
                android.content.Intent intent = new android.content.Intent(android.content.Intent.ACTION_VIEW);
                android.net.Uri uri = android.net.Uri.fromFile(file);
                
                try {
                    // Try with disableDeathOnFileUriExposure hack for quick support
                    try {
                        java.lang.reflect.Method m = android.os.StrictMode.class.getMethod("disableDeathOnFileUriExposure");
                        m.invoke(null);
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                    
                    intent.setDataAndType(uri, "application/pdf");
                    intent.addFlags(android.content.Intent.FLAG_ACTIVITY_NEW_TASK);
                    startActivity(intent);
                } catch (Exception e) {
                     openDownloads(); // Fallback
                }
            } else {
                 android.widget.Toast.makeText(this, "Resume not found", android.widget.Toast.LENGTH_SHORT).show();
            }
        }
    }
}
