package com.calculatorlauncher.app.launcher

import android.content.Context
import android.util.AttributeSet
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.widget.FrameLayout
import androidx.viewpager2.widget.ViewPager2
import kotlin.math.absoluteValue

/**
 * Lets apps RecyclerView scroll vertically inside vertical ViewPager2.
 * When list is at top and user swipes down → ViewPager goes back to home.
 */
class NestedScrollableHost @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null
) : FrameLayout(context, attrs) {

    private val touchSlop = ViewConfiguration.get(context).scaledTouchSlop
    private var initialX = 0f
    private var initialY = 0f

    private fun parentViewPager(): ViewPager2? {
        var p: Any? = parent
        while (p is View) {
            if (p is ViewPager2) return p
            p = p.parent
        }
        return null
    }

    override fun onInterceptTouchEvent(ev: MotionEvent): Boolean {
        handle(ev)
        return super.onInterceptTouchEvent(ev)
    }

    override fun onTouchEvent(ev: MotionEvent): Boolean {
        handle(ev)
        return super.onTouchEvent(ev)
    }

    private fun handle(e: MotionEvent) {
        val vp = parentViewPager() ?: return
        val child = getChildAt(0) ?: return
        when (e.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                initialX = e.x
                initialY = e.y
                parent.requestDisallowInterceptTouchEvent(true)
            }
            MotionEvent.ACTION_MOVE -> {
                val dx = e.x - initialX
                val dy = e.y - initialY
                val absDx = dx.absoluteValue
                val absDy = dy.absoluteValue
                if (absDy > touchSlop && absDy > absDx) {
                    // Swiping down and child cannot scroll up further → let ViewPager take over (go home)
                    val scrollingDown = dy > 0
                    val canScrollUp = child.canScrollVertically(-1)
                    if (scrollingDown && !canScrollUp) {
                        parent.requestDisallowInterceptTouchEvent(false)
                    } else {
                        parent.requestDisallowInterceptTouchEvent(true)
                    }
                }
            }
        }
    }
}
