const std = @import("std");
const log = std.log.scoped(.heartbeat);

pub const BeatError = error{ HttpClientError, StatusError } || std.fmt.AllocPrintError;

pub fn Beat(allocator: std.mem.Allocator, url: []const u8) BeatError!void {
    if (url.len == 0) {
        log.debug("Skipping heartbeat", .{});
        return;
    }

    log.debug("Sending heartbeat: {s}", .{url});
    var client = std.http.Client{
        .allocator = allocator,
    };
    defer client.deinit();

    const result = client.fetch(.{
        .method = .GET,
        .location = .{
            .url = url,
        },
    }) catch |err| {
        switch (err) {
            std.mem.Allocator.Error.OutOfMemory => return BeatError.OutOfMemory,
            else => {
                log.err("Http client error: {s}", .{@errorName(err)});
                return BeatError.HttpClientError;
            },
        }
    };

    log.debug("Result: {d}", .{result.status});

    if (result.status != .ok) {
        return BeatError.StatusError;
    }
}
