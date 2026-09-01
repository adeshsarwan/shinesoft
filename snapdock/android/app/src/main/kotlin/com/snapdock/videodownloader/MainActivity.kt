package com.snapdock.videodownloader

import android.app.Activity
import android.content.ContentResolver
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.snapdock.videodownloader/folder"
    private var folderResultCallback: MethodChannel.Result? = null
    private var listFilesCallback: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "openWhatsAppFolderPicker" -> {
                    folderResultCallback = result
                    openWhatsAppFolderPicker()
                }
                "listFilesInFolder" -> {
                    listFilesCallback = result
                    val uriString = call.argument<String>("uri")
                    if (uriString != null) {
                        listFilesInFolder(Uri.parse(uriString))
                    } else {
                        result.error("INVALID_URI", "URI is null", null)
                    }
                }
                "checkDefaultWhatsAppFolder" -> {
                    val path = checkDefaultWhatsAppFolder()
                    result.success(path)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun openWhatsAppFolderPicker() {
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or
                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                        Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION
            }
            
            // Open file manager directly at .Statuses so user doesn't navigate manually.
            // EXTRA_INITIAL_URI supported from API 26; path encoded (dot in .Statuses as %2E for compatibility).
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val treeUri = Uri.parse(
                    "content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia%2Fcom.whatsapp%2FWhatsApp%2FMedia%2F%2EStatuses"
                )
                putExtra(DocumentsContract.EXTRA_INITIAL_URI, treeUri)
            }
            putExtra(Intent.EXTRA_TITLE, "Select WhatsApp Status Folder (.Statuses)")
        }
        startActivityForResult(intent, 1001)
    }

    private fun checkDefaultWhatsAppFolder(): String {
        val whatsappPaths = listOf(
            "Android/media/com.whatsapp/WhatsApp/Media/.Statuses",
            "WhatsApp/Media/.Statuses",
            "Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses",
            "WhatsApp Business/Media/.Statuses"
        )

        val externalStorage = getExternalFilesDir(null)?.parentFile?.parentFile
        if (externalStorage != null) {
            for (relativePath in whatsappPaths) {
                val folder = File(externalStorage, relativePath)
                if (folder.exists() && folder.isDirectory) {
                    return folder.absolutePath
                }
            }
        }
        return ""
    }

    private fun listFilesInFolder(uri: Uri) {
        try {
            val contentResolver = applicationContext.contentResolver
            val treeDocumentId = DocumentsContract.getTreeDocumentId(uri)
            val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(uri, treeDocumentId)
            
            val files = mutableListOf<String>()
            contentResolver.query(
                childrenUri,
                arrayOf(
                    DocumentsContract.Document.COLUMN_DISPLAY_NAME,
                    DocumentsContract.Document.COLUMN_MIME_TYPE,
                    DocumentsContract.Document.COLUMN_DOCUMENT_ID
                ),
                null,
                null,
                null
            )?.use { cursor ->
                while (cursor.moveToNext()) {
                    val displayName = cursor.getString(0)
                    val mimeType = cursor.getString(1)
                    val documentId = cursor.getString(2)
                    
                    // Check if it's a media file
                    if (mimeType != null && (mimeType.startsWith("image/") || mimeType.startsWith("video/"))) {
                        val documentUri = DocumentsContract.buildDocumentUriUsingTree(uri, documentId)
                        
                        // Create a temporary file copy in app's cache directory
                        val tempFile = createTempFileFromUri(documentUri, displayName)
                        if (tempFile != null && tempFile.exists()) {
                            files.add(tempFile.absolutePath)
                        }
                    }
                }
            }
            
            listFilesCallback?.success(files)
            listFilesCallback = null
            
        } catch (e: Exception) {
            listFilesCallback?.error("LIST_ERROR", e.message, null)
            listFilesCallback = null
        }
    }

    private fun createTempFileFromUri(uri: Uri, fileName: String): File? {
        return try {
            val contentResolver = applicationContext.contentResolver
            val tempDir = File(cacheDir, "temp_whatsapp_status")
            if (!tempDir.exists()) {
                tempDir.mkdirs()
            }
            
            // Create unique filename to avoid conflicts
            val uniqueFileName = "${System.currentTimeMillis()}_$fileName"
            val tempFile = File(tempDir, uniqueFileName)
            
            contentResolver.openInputStream(uri)?.use { inputStream ->
                FileOutputStream(tempFile).use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
            }
            
            if (tempFile.exists() && tempFile.length() > 0) {
                tempFile
            } else {
                null
            }
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == 1001) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                val uri = data.data
                if (uri != null) {
                    // Take persistable URI permission
                    try {
                        contentResolver.takePersistableUriPermission(
                            uri,
                            Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
                        )
                        folderResultCallback?.success(uri.toString())
                    } catch (e: Exception) {
                        // Still return success even if permission persistence fails
                        folderResultCallback?.success(uri.toString())
                    }
                } else {
                    folderResultCallback?.error("NO_URI", "No URI returned", null)
                }
            } else {
                folderResultCallback?.error("CANCELLED", "User cancelled folder selection", null)
            }
            folderResultCallback = null
        }
    }
}