using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace BizzyBeeGames.DotConnect
{
	[System.Serializable]
	public class BundleInfo
	{
		#region Inspector Variables

		[SerializeField] private string			bundleName;
		[SerializeField] private PackListItem	packListItemPrefab;
		[SerializeField] private List<PackInfo> packInfos;

		#endregion

		#region Properties

		public string			BundleName			{ get { return bundleName; } }
		public PackListItem		PackListItemPrefab	{ get { return packListItemPrefab; } }
		public List<PackInfo>	PackInfos			{ get { return packInfos; } }

		#endregion
	}
}
