const std = @import("std");
const Regex = @import("regex").Regex;
const Allocator = std.mem.Allocator;

pub const String = []const u8;
pub const BrowserId = String;
pub const Cmd = String;

pub const Filter = struct {
	browser: BrowserId,
	matcher: Regex,
};
pub const Config = struct {
	cmds: std.StringHashMap(Cmd), //shouldbe AutoHashMap, but it can derive hash
	default: BrowserId,
	filters: []Filter
};

fn pos(str: String, start: usize, target: u8) ?usize{
	var index: usize = start;
	while (index < str.len) : (index += 1) {
		if (str[index] == target) {
			return index;
		}
	}
	return null;
}

pub fn read(path: String, allocator: Allocator) ?Config {
	var file = std.fs.cwd().openFile(path, .{}) catch {
		std.debug.print("Can't open config at {s}\n", .{path});
		return null;
	};
	defer file.close();
	
	var default: ?BrowserId = null;
	var cmds = std.StringHashMap(Cmd).init(allocator);
	var filters = std.ArrayList(Filter).init(allocator);

	var buf_reader = std.io.bufferedReader(file.reader());
	var in_stream = buf_reader.reader();
	var buf: [1024]u8 = undefined;
	var line_index: u32 = 0;
	while (in_stream.readUntilDelimiterOrEof(&buf, '\n') catch |err| {
		std.debug.print("Error during file reading: {}\n", .{err});		
		return null;		
	}) |line|: (line_index += 1)  {
        //std.debug.print("reading '{s}'\n", .{line});
		if (line.len == 0){
			continue;
		} else if (std.mem.eql(u8,line[0..3],"cmd")){
			const next_space_pos = pos(line, 4, ' ') orelse {
				std.debug.print("Invalid cmd at line {d}, expecting 'cmd %browserid% %cmd%'\n", .{line_index});
				return null;
			};
            const browser_id = allocator.dupe(u8, line[4..next_space_pos]) catch {
                std.debug.print("Can't allocate memory\n", .{});
                std.os.exit(200);
            };
            const cmd = allocator.dupe(u8, line[next_space_pos+1..]) catch {
                std.debug.print("Can't allocate memory\n", .{});
                std.os.exit(200);
            };
			cmds.put(browser_id, cmd) catch |err| {
				std.debug.print("Allocation issue at line {d}: {}'\n", .{line_index, err});
				return null;
			};			
		} else if (std.mem.eql(u8, line[0..7],"default")){
			const space_pos = pos(line, 7, ' ') orelse {
				std.debug.print("Invalid default at line {d}, expecting 'default %browserid%' from [", .{line_index});
                var key_iter = cmds.keyIterator();
                while (key_iter.next()) |key|{
    				std.debug.print("'{s}', ", .{key.*});
                }
                std.debug.print("]\n", .{});
				return null;
			};
			if (default != null){
			std.debug.print("Default is already defined. Duplicate definition at line {d}'\n", .{line_index});
				return null;			
			}
			default = allocator.dupe(u8, line[space_pos+1..]) catch {
                std.debug.print("Can't allocate memory\n", .{});
                std.os.exit(200);
            };
			if (!cmds.contains(default.?)){
				std.debug.print("There is no cmd defined for default '{?s}' at line {d}, expecting one of [", .{default, line_index});
                var key_iter = cmds.keyIterator();
                while (key_iter.next()) |key|{
    				std.debug.print("'{s}', ", .{key.*});
                }
                std.debug.print("]\n", .{});
				return null;							
			}
		} else {
			const first_space_pos = pos(line, 0, ' ') orelse {
				std.debug.print("Invalid filter at line {d}, expecting '%browserid% %regex%'\n", .{line_index});
				return null;
			};
			const regex = Regex.compile(allocator, line[first_space_pos+1..]) catch |err| {
				std.debug.print("Invalid regex at line {d}: {}\n", .{line_index, err});
				return null;
			};
			const browser_id = allocator.dupe(u8, line[0..first_space_pos]) catch {
                std.debug.print("Can't allocate memory\n", .{});
                std.os.exit(200);
            };
			filters.append(Filter{.browser = browser_id, .matcher = regex}) catch |err| {
				std.debug.print("Allocation issue at line {d}: {}'\n", .{line_index, err});
				return null;
			};			
		}
	}
    if (default) |def|{
    	return Config{.cmds = cmds, .default = def, .filters = filters.items};
    } else {
		std.debug.print("No default was defined. There should be line 'default %browserid%'\n", .{});
        return null;
    }
}
