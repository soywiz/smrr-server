﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Net.Sockets;
using CSharpUtils.Extensions;
using System.Runtime.InteropServices;
using System.IO;
using SimpleMassiveRealtimeRankingServer.Server.PacketHandlers;
using System.Reflection;
using CSharpUtils;
using System.Threading;
using CSharpUtils.Threading;

namespace SimpleMassiveRealtimeRankingServer.Server
{
	public class ClientHandler : BaseClientHandler
	{
		ServerManager ServerManager;

		public ClientHandler(ServerManager ServerManager, TcpClient TcpClientSocket)
			: base(TcpClientSocket)
		{
			this.ServerManager = ServerManager;
		}

		override protected void HandlePacket(Packet ReceivedPacket)
		{
			var PacketToSend = new Packet(ReceivedPacket.Type);
			BasePacketHandler PacketHandler;

			switch (ReceivedPacket.Type)
			{
				case Packet.PacketType.GetElementOffset:
					PacketHandler = new GetElementOffsetHandler();
					break;
				case Packet.PacketType.GetRankingIdByName:
					PacketHandler = new GetRankingIdByNameHandler();
					break;
				case Packet.PacketType.GetRankingInfo:
					PacketHandler = new GetRankingInfoHandler();
					break;
				case Packet.PacketType.GetVersion:
					PacketHandler = new GetVersionHandler();
					break;
				case Packet.PacketType.ListElements:
					PacketHandler = new ListElementsHandler();
					break;
				case Packet.PacketType.Ping:
					PacketHandler = new PingHandler();
					break;
				case Packet.PacketType.RemoveAllElements:
					PacketHandler = new RemoveAllElementsHandler();
					break;
				case Packet.PacketType.RemoveElements:
					PacketHandler = new RemoveElementsHandler();
					break;
				case Packet.PacketType.SetElements:
					PacketHandler = new SetElementsHandler();
					break;
				default:
					throw (new NotImplementedException("Can't handle packet '" + ReceivedPacket + "'"));
			}
			//Console.WriteLine(TypeUtils.GetTypesExtending(typeof(IPacketHandler)).ToStringArray());

			PacketHandler.SetServerManager(ServerManager);
			PacketHandler.FastParseRequest(ReceivedPacket);
			int ThreadAffinity = PacketHandler.GetThreadAffinityAfterParseRequest();

			ScheduleTask(ThreadAffinity, () =>
			{
				try
				{
					PacketHandler.Execute(PacketToSend);
					PacketToSend.WritePacketTo(this.ClientNetworkStream);
				}
				catch (Exception Exception)
				{
					Console.WriteLine(Exception);
					TcpClientSocket.Close();
				}
			});
		}

		void ScheduleTask(int ThreadAffinity, Action Task)
		{
			ServerManager.CustomThreadPool.AddTask(ThreadAffinity, Task);
			//Task();
		}
	}
}