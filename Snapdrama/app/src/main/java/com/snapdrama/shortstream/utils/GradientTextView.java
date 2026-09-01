package com.snapdrama.shortstream.utils;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.LinearGradient;
import android.graphics.Paint;
import android.graphics.Shader;
import android.util.AttributeSet;

public class GradientTextView extends androidx.appcompat.widget.AppCompatTextView {

    private Paint strokePaint;

    public GradientTextView(Context context) {
        super(context);
        init();
    }

    public GradientTextView(Context context, AttributeSet attrs) {
        super(context, attrs);
        init();
    }

    public GradientTextView(Context context, AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init();
    }

    private void init() {
        strokePaint = new Paint(getPaint());
        strokePaint.setStyle(Paint.Style.STROKE);
        strokePaint.setColor(Color.WHITE);

        float strokeWidth = getResources().getDisplayMetrics().density * 1;
        strokePaint.setStrokeWidth(strokeWidth);
        strokePaint.setAntiAlias(true);
    }

    @Override
    protected void onSizeChanged(int w, int h, int oldw, int oldh) {
        super.onSizeChanged(w, h, oldw, oldh);

        if (w > 0 && h > 0) {
            Shader shader = new LinearGradient(
                    0, 0,
                    0, h,
                    new int[]{
                            Color.parseColor("#F9DE95"),
                            Color.parseColor("#EBCB7C"),
                            Color.parseColor("#E3BB66"),
                            Color.parseColor("#FFECCA"),
                            Color.parseColor("#DBBA65"),
                            Color.parseColor("#A6864A"),
                            Color.parseColor("#4E370E")
                    },
                    null,
                    Shader.TileMode.CLAMP
            );
            getPaint().setShader(shader);
        }
    }

    @Override
    protected void onDraw(Canvas canvas) {
        // Draw border
        canvas.drawText(
                getText().toString(),
                getPaddingLeft(),
                getBaseline(),
                strokePaint
        );

        // Draw gradient text
        super.onDraw(canvas);
    }
}