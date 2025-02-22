const Environment = @This();

const std = @import("std");
const builtin = @import("builtin");
const log = std.log.scoped(.Environment);

const EnvironmentError = error{
    EnvMapError,
    InvalidToken,
    InvalidZoneId,
    InvalidUpdateInterval,
    InvalidIdentificationComment,
    InvalidProxied,
    MemoryError,
};

token: []const u8 = undefined,
zone_id: []const u8 = undefined,
update_interval: u64,
identification_comment: []const u8 = undefined,
dns_host: []const u8 = undefined,
proxied: bool,
heartbeat_url: []const u8 = undefined,

fn strip_crlf(data: []const u8) []const u8 {
    for (data, 0..) |c, i| {
        if (c == '\r' or c == '\n') {
            return data[0..i];
        }
    }
    return data;
}

pub fn init(allocator: std.mem.Allocator) EnvironmentError!Environment {
    log.debug("Getting EnvMap", .{});
    var env = std.process.getEnvMap(allocator) catch return EnvironmentError.EnvMapError;
    defer env.deinit();
    // if (builtin.mode == .Debug) {
    //     var iter = env.iterator();
    //     while (iter.next()) |entry| {
    //         log.debug("{s}={s}", .{ entry.key_ptr.*, entry.value_ptr.* });
    //     }
    // }

    const token = strip_crlf(env.get("TOKEN") orelse return EnvironmentError.InvalidToken);
    log.info("Token: {s}...", .{token[0..3]});
    const zone_id = strip_crlf(env.get("ZONE_ID") orelse return EnvironmentError.InvalidZoneId);
    log.info("Zone ID: {s}...", .{zone_id[0..8]});
    const update_interval_str = strip_crlf(env.get("UPDATE_INTERVAL") orelse "0");
    const update_interval = std.fmt.parseInt(u64, update_interval_str, 10) catch return EnvironmentError.InvalidUpdateInterval;
    log.info("Update Interval: {d}", .{update_interval});
    const identification_comment = strip_crlf(env.get("IDENTIFICATION_COMMENT") orelse return EnvironmentError.InvalidIdentificationComment);
    log.info("Identification Comment: {s}", .{identification_comment});
    const dns_host = strip_crlf(env.get("DNS_HOST") orelse "1.1.1.1");
    log.info("DNS Host: {s}", .{dns_host});
    const proxied_str = strip_crlf(env.get("PROXIED") orelse "1");
    const proxied = std.fmt.parseInt(u32, proxied_str, 10) catch return EnvironmentError.InvalidProxied;
    log.info("Proxied: {d}", .{proxied});
    const heartbeat_url = strip_crlf(env.get("HEARTBEAT_URL") orelse "");
    log.info("Heartbeat URL: {s}", .{heartbeat_url});

    const result = Environment{
        .token = std.fmt.allocPrint(allocator, "{s}", .{token}) catch return EnvironmentError.MemoryError,
        .zone_id = std.fmt.allocPrint(allocator, "{s}", .{zone_id}) catch return EnvironmentError.MemoryError,
        .identification_comment = std.fmt.allocPrint(allocator, "{s}", .{identification_comment}) catch return EnvironmentError.MemoryError,
        .dns_host = std.fmt.allocPrint(allocator, "{s}", .{dns_host}) catch return EnvironmentError.MemoryError,
        .update_interval = update_interval,
        .proxied = proxied > 0,
        .heartbeat_url = std.fmt.allocPrint(allocator, "{s}", .{heartbeat_url}) catch return EnvironmentError.MemoryError,
    };
    return result;
}

pub fn deinit(self: Environment, allocator: std.mem.Allocator) void {
    allocator.free(self.token);
    allocator.free(self.zone_id);
    allocator.free(self.identification_comment);
    allocator.free(self.dns_host);
}
