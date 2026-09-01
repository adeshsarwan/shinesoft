package com.calculatorlauncher.app.launcher

import android.app.WallpaperManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Outline
import android.os.Bundle
import android.view.View
import android.view.ViewOutlineProvider
import android.widget.ImageView
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import com.calculatorlauncher.app.R
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors
import kotlin.concurrent.thread

/**
 * ========== LAUNCHER_MODE_START ==========
 * Wallpaper Discover — Unsplash-style categories (Nature, Seascapes, Space, City).
 * ========== LAUNCHER_MODE_END ==========
 */
class WallpaperDiscoverActivity : AppCompatActivity() {

    private val executor = Executors.newFixedThreadPool(4)

    private data class Category(
        val titleRes: Int,
        val imageUrl: String,
        val cardId: Int
    )

    private val categories = listOf(
        Category(
            R.string.wallpaper_nature,
            "https://images.unsplash.com/photo-1501785888041-af3ee2854945?w=600&q=80",
            R.id.cardNature
        ),
        Category(
            R.string.wallpaper_seascapes,
            "https://images.unsplash.com/photo-1505142468610-359e7d316be0?w=600&q=80",
            R.id.cardSeascapes
        ),
        Category(
            R.string.wallpaper_space,
            "https://images.unsplash.com/photo-1462331940025-496dfbfc7564?w=600&q=80",
            R.id.cardSpace
        ),
        Category(
            R.string.wallpaper_city,
            "https://images.unsplash.com/photo-1514565131-fce0801e5785?w=600&q=80",
            R.id.cardCity
        )
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_wallpaper_discover)

        val radius = resources.displayMetrics.density * 14f
        val roundOutline = object : ViewOutlineProvider() {
            override fun getOutline(view: View, outline: Outline) {
                outline.setRoundRect(0, 0, view.width, view.height, radius)
            }
        }

        categories.forEach { cat ->
            val card = findViewById<View>(cat.cardId)
            card.outlineProvider = roundOutline
            card.clipToOutline = true
            card.findViewById<TextView>(R.id.tvCategory).setText(cat.titleRes)
            val image = card.findViewById<ImageView>(R.id.imgCategory)
            loadImage(cat.imageUrl, image)
            card.setOnClickListener { confirmSetWallpaper(cat) }
        }
    }

    private fun confirmSetWallpaper(cat: Category) {
        AlertDialog.Builder(this)
            .setTitle(cat.titleRes)
            .setMessage(R.string.wallpaper_set_confirm)
            .setPositiveButton(R.string.wallpaper_set_action) { _, _ ->
                setAsWallpaper(cat.imageUrl)
            }
            .setNegativeButton(android.R.string.cancel, null)
            .show()
    }

    private fun setAsWallpaper(url: String) {
        Toast.makeText(this, R.string.wallpaper_setting, Toast.LENGTH_SHORT).show()
        thread {
            val bmp = downloadBitmap(url)
            runOnUiThread {
                if (bmp == null) {
                    Toast.makeText(this, R.string.wallpaper_failed, Toast.LENGTH_SHORT).show()
                    return@runOnUiThread
                }
                try {
                    WallpaperManager.getInstance(this).setBitmap(bmp)
                    Toast.makeText(this, R.string.wallpaper_set_done, Toast.LENGTH_SHORT).show()
                } catch (_: Exception) {
                    Toast.makeText(this, R.string.wallpaper_failed, Toast.LENGTH_SHORT).show()
                }
            }
        }
    }

    private fun loadImage(url: String, target: ImageView) {
        executor.execute {
            val bmp = downloadBitmap(url) ?: return@execute
            runOnUiThread {
                if (!isFinishing) target.setImageBitmap(bmp)
            }
        }
    }

    private fun downloadBitmap(url: String): Bitmap? = try {
        val conn = (URL(url).openConnection() as HttpURLConnection).apply {
            connectTimeout = 10000
            readTimeout = 10000
            instanceFollowRedirects = true
        }
        conn.inputStream.use { BitmapFactory.decodeStream(it) }
    } catch (_: Exception) {
        null
    }

    override fun onDestroy() {
        super.onDestroy()
        executor.shutdownNow()
    }
}
