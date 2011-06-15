module tests.excollections;

import excollections;
import user;

import std.datetime;
import std.stdio;
import core.memory;

unittest {
	alias RedBlackTreeEx!(int, RedBlackOptions.HAS_STATS) SimpleStats;
	SimpleStats stats = new SimpleStats(delegate(int a, int b) { return a < b; });
	stats.insert(5);
	stats.insert(4);
	stats.insert(6);
	stats.insert(3);
	stats.insert(2);
	stats.insert(1);
	stats.insert(6);
	stats.insert(7);
	stats.insert(8);
	stats.insert(9);
	stats.insert(10);
	
	writefln("*********************************************");
	
	stats.printTree();
	stats.debugValidateTree();

	//stats.removeKey(7);
	stats.removeKey(5);
	
	stats.printTree();
	stats.debugValidateTree();
}

unittest {
	UserStats userStats = new UserStats();
	Random gen;
	foreach (z; [0, 1]) {
		int time = 1308050393 + z;
		for (int n = 0; n < 5; n++) {
			userStats.setUser(User.create(n).setScore(uniform(0, 500, gen), time + uniform(-50, 4, gen)));
			userStats.usersByScores[0].debugValidateTree();
		}
		
		//userStats.setUser(User.create(1000).setScore(200, time + 0));
		//userStats.setUser(User.create(1001).setScore(300, time + 0));
		//userStats.setUser(User.create(1000).setScore(300, time + 1));
		
		writefln("------------------------------");
		userStats.usersByScores[0].printTree();
		
		userStats.usersByScores[0].debugValidateTree();
		
		foreach (user; userStats.usersByScores[0].all().skip(0).limit(20)) {
			writefln("%s", user);
		}
	} 
}

unittest {
	Random gen;
	
	//writefln("[1]");
	UserStats userStats = new UserStats();
	//writefln("[2]");
	for (int n = 0; n < 1000; n++) {
		int score;
		score = (n < 20) ? 2980 : uniform(0, 3000, gen);
		//writefln("[1:%d]", n);
		User user = User.create(n).setScore(score, 10000 - n * 2);
		//writefln("[a]");
		userStats.setUser(user);
	}
	//writefln("[3]");
	userStats.setUser(User.create(1000).setScore(99, 400));
	userStats.setUser(User.create(1001).setScore(1000, 400));
	userStats.setUser(User.create(1000).setScore(20000, 400));
	int k;
	
	writefln("-----------------------------");
	
	k = 0;
	foreach (user; userStats.usersByScores[0].all()) {
		writefln("%d: %s", k + 1, user);
		k++;
	}
	
	writefln("-----------------------------");
	
	k = 0;
	foreach (user; userStats.usersByScores[0].all().limit(10)) {
		writefln("%d: %s", k + 1, user);
		k++;
	}

	foreach (indexToSearch; [300, 1001, 1000]) {	
		writefln("-----------------------------");
		
		writefln("Locate user(%d) : %d", indexToSearch, userStats.locateById(indexToSearch) + 1);
		
		writefln("-----------------------------");
		
		int skipCount = userStats.locateById(indexToSearch);
		k = skipCount;
		foreach (user; userStats.usersByScores[0].all().skip(skipCount).limit(10)) {
			writefln("%d - %s", k + 1, user);
			k++;
		}
	}
	
	writefln("-----------------------------");
}

void measurePerformance() {
	void measure(string desc, void delegate() dg) {
		auto start = Clock.currTime;
		dg();
		auto end = Clock.currTime;
		writefln("Time('%s'): %s", desc, end - start);
		writefln("");
	}
	
	void measurePerformance2(bool useStats)() {
		writefln("---------------------------------------");
		writefln("measurePerformance(useStats=%s)", useStats);
		writefln("---------------------------------------");
		
		//RedBlackTree(T, alias less = "a < b", bool allowDuplicates = false, bool hasStats = false)
		
		auto start = Clock.currTime;
		measure("Total", {
			int itemSize = 1_000_000;
			
			//auto items = new RedBlackTreeEx!(User, User.compareByScore, false, useStats)();
			auto items = new RedBlackTreeEx!(User, useStats ? RedBlackOptions.HAS_STATS : RedBlackOptions.NONE)(User.getCompareByScoreIndex(0));
			User generate(uint id) {
				return new User(id, id * 100, id);
			}
		
			writefln("NodeSize: %d", (*items._end).sizeof);
			
			//for (int n = itemSize; n >= 11; n--) {
			measure(std.string.format("Insert(%d) items", itemSize), {
				for (int n = 0; n < itemSize; n++) {
					items.insert(generate(n));
				}
			});
			
			items.removeKey(generate(100_000));
			items.removeKey(generate(700_000));
	
			measure(std.string.format("locateNodeAtPosition"), {
				for (int n = 0; n < 40; n++) {
					int result = items.locateNodeAtPosition(800_000).value.userId;
					if (n == 40 - 1) {
						writefln("%s", result);
					}
				}
			});
			
			measure("IterateUpperBound", {
				foreach (item; items.upperBound(generate(1_000_000 - 100_000))) {
					//writefln("Item: %s", item);
				}
			});
		
			measure("LengthAll", {
				writefln("%d", items.all.length);
			});
			measure("Length(skipx40:800_000)", {
				for (int n = 0; n < 40; n++) {
					int result = items.all.skip(800_000).length;
					//int result = items.all[800_000..items.all.length].length;
					if (n == 40 - 1) {
						writefln("%d", items.all.skip(800_000).front.userId);
						writefln("%d", items.all.skip(800_000).back.userId);
						writefln("%d", result);
					}
				}
			});
			
			measure("Length(skip+limitx40:100_000,600_000)", {
				for (int n = 0; n < 40; n++) {
					//int result = items.all.skip(100_000).limit(600_000).length;
					int result = items.all[100_000 .. 700_000].length;
					if (n == 40 - 1) {
						writefln("%d", items.all.skip(100_000).limit(600_000).front.userId);
						writefln("%d", items.all.skip(100_000).limit(600_000).back.userId);
						writefln("%d", result);
					}
				}
			});
			measure("Length(lesserx40)", {
				for (int n = 0; n < 40; n++) {
					int result = items.countLesser(items._find(generate(1_000_000 - 10)));
					if (n == 40 - 1) writefln("%d", result);
				}
			});
			measure("LengthBigRangex40", {
				for (int n = 0; n < 40; n++) {
					int result = items.upperBound(generate(1_000_000 - 900_000)).length;
					if (n == 40 - 1) writefln("%d", result);
				}
			});
			
			//items._end._left.printTree();
			//writefln("%s", *items._find(5));
			//foreach (item; items) writefln("%d", item);
			static if (useStats) {
				measure("Count all items position one by one (only with stats) O(N*log(N))", {
					for (int n = 0; n < itemSize; n++) {
						if (n == 100_000 || n == 700_000) continue;
			
						scope user = new User(n, n * 100, n);
						
						//writefln("%d", count);
						//writefln("-----------------------------------------------------");
						//writefln("######## Count(%d): %d", n, count);
						/*
						if (n > 500) {
							assert(count == n - 1);
						} else {
							assert(count == n);
						}
						*/
						static if (useStats) {
							int count = items.countLesser(items._find(user));
							
							int v = n;
							if (n > 100_000) v--;
							if (n > 700_000) v--;
							assert(count == v);
						}
					}
				});
			}
		});
	}

	GC.disable();
	{
		measurePerformance2!(true);
		measurePerformance2!(false);
	}
	GC.enable();
	GC.collect();
}