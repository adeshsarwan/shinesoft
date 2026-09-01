using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

namespace BizzyBeeGames.DotConnect
{
	public class GameEventManager : EventManager<GameEventManager>
	{
		#region Member Variables

		// Event Ids
		public const string EventId_BundleSelected			= "BundleSelected";
		public const string EventId_PackSelected			= "PackSelected";
		public const string EventId_ActiveLevelCompleted	= "ActiveLevelCompleted";
		public const string EventId_LevelStarted			= "LevelStarted";
		public const string EventId_StarsIncreased			= "StarsIncreased";

		// Event Id data types
		private static readonly Dictionary<string, List<System.Type>> eventDataTypes = new Dictionary<string, List<System.Type>>()
		{
			{ EventId_BundleSelected, new List<System.Type>() { typeof(BundleInfo) } },
			{ EventId_PackSelected, new List<System.Type>() { typeof(PackInfo) } },
			{ EventId_ActiveLevelCompleted, new List<System.Type>() { typeof(int) } },
			{ EventId_LevelStarted, new List<System.Type>() {} },
			{ EventId_StarsIncreased, new List<System.Type>() {} }
		};

		#endregion

		#region Protected Methods

		protected override Dictionary<string, List<Type>> GetEventDataTypes()
		{
			return eventDataTypes;
		}

		#endregion
	}
}
