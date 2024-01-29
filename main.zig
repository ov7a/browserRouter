const std = @import("std");
const Regex = @import("regex").Regex;
const cfg = @import("config.zig");

const String = cfg.String;
const Cmd = cfg.Cmd;
const Config = cfg.Config;

fn getCmd(config: Config, link: String) ?Cmd {
	var browser = config.default;
	for (config.filters) |filter|{
		var matcher = filter.matcher; // just to make compiler happy
		if (matcher.match(link) catch false){
			browser = filter.browser;
			break;
		}
	}
	return config.cmds.get(browser) orelse {
		std.debug.print("Can't find cmd for browser '{s}'. Recheck your config.", .{browser});
		return null;
	};
}

fn configPath(allocator: std.mem.Allocator) !String {
    const cwd = try std.fs.selfExeDirPathAlloc(allocator);
    var paths = [_]String {cwd, "config.cfg"};
    return try std.fs.path.join(allocator, &paths);
}

pub fn main() !void {
	var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
	defer arena.deinit();
	const allocator = arena.allocator();

	var args = try std.process.ArgIterator.initWithAllocator(allocator);
	defer args.deinit();
	
	_ = args.next(); // args[0], ignore
	
	if (args.next()) |link| {
        const config_path = configPath(allocator) catch |err| {
			std.debug.print("Can't get config path: {}\n", .{err});
			std.os.exit(1);
        };
		const config = cfg.read(config_path, allocator) orelse {
			std.debug.print("Can't parse config.cfg\n", .{});
			std.os.exit(2);
		};
		const cmd = getCmd(config, link) orelse std.os.exit(2);
		std.debug.print("Got '{s}', launching '{s}'\n", .{link, cmd});
		const cmd_args = [_][]const u8{cmd, link};
		// either executes or returns an error
		const err = std.process.execv(allocator, &cmd_args); 
		std.debug.print("Failed to execute command: {}\n", .{err});
		std.os.exit(3);
	} else {
		std.debug.print("No link passed\n", .{});
		std.os.exit(4);
	}
}
