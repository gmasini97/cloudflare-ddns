const std = @import("std");
const builtin = @import("builtin");

pub const std_options = .{
    .log_level = if (builtin.mode == .Debug) .debug else .info,
};

const log = std.log.scoped(.main);
const Environment = @import("Environment.zig");
const cloudflare = @import("cloudflare.zig");
const heartbeat = @import("heartbeat.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const deinit_status = gpa.deinit();
        if (deinit_status != .ok) {
            @panic("Failed to deinitialize allocator");
        }
    }
    const allocator = gpa.allocator();

    const env = try Environment.init(allocator);
    defer env.deinit(allocator);

    var first = true;
    var count: u32 = 0;
    while ((first or env.update_interval > 0) and (builtin.mode != .Debug or count < 3)) : (count += 1) {
        defer {
            heartbeat.Beat(allocator, env.heartbeat_url) catch |err| {
                switch (err) {
                    heartbeat.BeatError.OutOfMemory => {
                        @panic("Out of memory");
                    },
                    else => {
                        log.err("Failed to heartbeat: {s}", .{@errorName(err)});
                    },
                }
            };

            if (env.update_interval > 0) {
                std.time.sleep(@as(u64, env.update_interval) * std.time.ns_per_s);
            }
        }

        first = false;

        const rec = cloudflare.GetCommentedRecord(allocator, env.token, env.zone_id, env.identification_comment) catch |err| {
            switch (err) {
                cloudflare.GetCommentedRecordError.OutOfMemory => {
                    return err;
                },
                else => {
                    log.err("Failed to get record: {s}", .{@errorName(err)});
                    continue;
                },
            }
        };
        defer rec.deinit(allocator);

        const ipinfo = cloudflare.GetCurrentIp(allocator) catch |err| {
            switch (err) {
                cloudflare.GetCurrentIpError.OutOfMemory => {
                    return err;
                },
                else => {
                    log.err("Failed to get current IP: {s}", .{@errorName(err)});
                    continue;
                },
            }
        };
        defer ipinfo.deinit(allocator);

        if (std.mem.eql(u8, rec.content, ipinfo.ip)) {
            log.info("IP is up to date {s}", .{rec.content});
        } else {
            log.info("Updating IP from {s} to {s}", .{ rec.content, ipinfo.ip });
            cloudflare.PatchRecord(allocator, env.token, env.zone_id, rec.id, ipinfo.ip, env.proxied) catch |err| {
                switch (err) {
                    cloudflare.PatchRecordError.OutOfMemory => {
                        return err;
                    },
                    else => {
                        log.err("Failed to patch record: {s}", .{@errorName(err)});
                        continue;
                    },
                }
            };
        }
    }
}
