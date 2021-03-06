﻿using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using CSharpUtils.Extensions;

namespace SimpleMassiveRealtimeRankingServer.Server
{
    public partial class ServerHandler
    {
        public struct RequestHeaderStruct
        {
            public int RankingIndexId;
        }

        public struct RequestEntryStruct
        {
            public uint UserId;
        }

#if NET_4_5
        async private Task<byte[]> HandlePacketAsync_RemoveElements(byte[] RequestContent)
        {
            var RequestContentStream = new MemoryStream(RequestContent);
            var RequestHeader = RequestContentStream.ReadStruct<RequestHeaderStruct>();

            await EnqueueTaskAsync((uint)RequestHeader.RankingIndexId, () =>
            {
                var RequestEntries = RequestContentStream.ReadStructVectorUntilTheEndOfStream<RequestEntryStruct>();
                var Index = ServerManager.ServerIndices[RequestHeader.RankingIndexId];
                foreach (var RequestEntry in RequestEntries)
                {
                    Index.Tree.Remove(Index.GetUserScore(RequestEntry.UserId));
                }
            });
            
            return new byte[0];
        }
#else
		private byte[] HandlePacket_RemoveElements(byte[] RequestContent)
		{
			var RequestContentStream = new MemoryStream(RequestContent);
			var RequestHeader = RequestContentStream.ReadStruct<RequestHeaderStruct>();

			{
				var RequestEntries = RequestContentStream.ReadStructVectorUntilTheEndOfStream<RequestEntryStruct>();
				var Index = ServerManager.ServerIndices[RequestHeader.RankingIndexId];
				foreach (var RequestEntry in RequestEntries)
				{
					Index.Tree.Remove(Index.GetUserScore(RequestEntry.UserId));
				}
			}

			return new byte[0];
		}
#endif
    }
}
