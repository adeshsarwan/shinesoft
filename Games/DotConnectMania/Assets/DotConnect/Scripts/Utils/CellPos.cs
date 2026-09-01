using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace BizzyBeeGames.DotConnect
{
	public class CellPos
	{
		public readonly int row;
		public readonly int col;

		public CellPos(int row, int col)
		{
			this.row = row;
			this.col = col;
		}

		public override int GetHashCode()
		{
			return ToString().GetHashCode();
		}

		public override bool Equals(object obj)
		{
			return obj is CellPos && (obj as CellPos).row == row && (obj as CellPos).col == col;
		}

		public override string ToString()
		{
			return string.Format(row + "_" + col);
		}
	}
}
