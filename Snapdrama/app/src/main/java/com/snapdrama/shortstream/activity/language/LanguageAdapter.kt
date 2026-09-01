package com.smsmessenger.chat.Language

import android.content.Context
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.RelativeLayout
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.snapdrama.shortstream.R
import com.snapdrama.shortstream.applicationPreference.ControlPreference

class LanguageAdapter(private val context: Context, private val list: List<Data>, private val showIcon : Boolean, private val setOnClick: SetOnClick) :
    RecyclerView.Adapter<LanguageAdapter.MyViewHolder>() {
    
    var selectedLanguageCode: String = ControlPreference.getAppLanguage()

    class MyViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        val dataText: TextView = itemView.findViewById(R.id.dataText)
        val dataText2: TextView = itemView.findViewById(R.id.dataText2)
        val icon: ImageView = itemView.findViewById(R.id.icon)
        val main: RelativeLayout = itemView.findViewById(R.id.main)
        val languageIcon: ImageView = itemView.findViewById(R.id.languageIcon)
//        val lotties: LottieAnimationView = itemView.findViewById(R.id.lotties)
    }

    interface SetOnClick {
        fun onClickItem(position: Int, view: ImageView)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): MyViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_data2, parent, false)
        return MyViewHolder(view)
    }

    override fun getItemCount(): Int {
        return list.size
    }

    override fun onBindViewHolder(holder: MyViewHolder, position: Int) {
        holder.dataText.text = list[position].text
        holder.dataText2.text = list[position].subText
        holder.icon.setImageResource(if (list[position].code == selectedLanguageCode) R.drawable.ic_selcted else R.drawable.ic_unselected)
        holder.itemView.setOnClickListener {
            selectedLanguageCode = list[position].code
            notifyDataSetChanged()
            setOnClick.onClickItem(position, holder.icon)
        }
        holder.languageIcon.setImageResource(list[position].image)
//        if (showIcon){
//            if (position == 0){
//                holder.lotties.visibility = View.VISIBLE
//            }else{
//                holder.lotties.visibility = View.GONE
//            }
//        }
    }
}
