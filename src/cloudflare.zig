const std = @import("std");
const log = std.log.scoped(.cloudflare);

pub const DNSRecord = struct {
    id: []const u8,
    zone_id: []const u8,
    name: []const u8,
    content: []const u8,

    pub fn deinit(self: DNSRecord, allocator: std.mem.Allocator) void {
        allocator.free(self.id);
        allocator.free(self.zone_id);
        allocator.free(self.name);
        allocator.free(self.content);
    }
};

const ListRecordsResult = struct {
    success: bool,
    result: []ListRecordsResultRecord,
};

const ListRecordsResultRecord = struct {
    id: []const u8,
    name: []const u8,
    content: []const u8,
};

pub const GetCommentedRecordError = error{
    StatusError,
    SuccessError,
    MultipleRecordsError,
    HttpClientError,
    JsonError,
} || std.fmt.AllocPrintError;

pub fn GetCommentedRecord(
    allocator: std.mem.Allocator,
    token: []const u8,
    zone_id: []const u8,
    identification_comment: []const u8,
) GetCommentedRecordError!DNSRecord {
    const authorization = try std.fmt.allocPrint(allocator, "Bearer {s}", .{token});
    defer allocator.free(authorization);

    const url = try std.fmt.allocPrint(
        allocator,
        "https://api.cloudflare.com/client/v4/zones/{s}/dns_records?comment.contains={s}",
        .{ zone_id, identification_comment },
    );
    defer allocator.free(url);

    const headers = &[_]std.http.Header{
        .{ .name = "Authorization", .value = authorization },
        .{ .name = "Content-Type", .value = "application/json" },
    };

    var client = std.http.Client{
        .allocator = allocator,
    };
    defer client.deinit();

    var response = std.ArrayList(u8).init(allocator);
    defer response.deinit();

    const result = client.fetch(.{
        .method = .GET,
        .location = .{
            .url = url,
        },
        .extra_headers = headers,
        .response_storage = .{
            .dynamic = &response,
        },
    }) catch |err| {
        switch (err) {
            std.mem.Allocator.Error.OutOfMemory => return GetCommentedRecordError.OutOfMemory,
            else => {
                log.err("Http client error: {s}", .{@errorName(err)});
                return GetCommentedRecordError.HttpClientError;
            },
        }
    };

    log.debug("Result: {d}", .{result.status});
    log.debug("Response: {s}", .{response.items});

    if (result.status != .ok) {
        return GetCommentedRecordError.StatusError;
    } else {
        const parsed = std.json.parseFromSlice(
            ListRecordsResult,
            allocator,
            response.items,
            .{
                .ignore_unknown_fields = true,
            },
        ) catch |err| {
            log.err("Json error: {s}", .{@errorName(err)});
            return GetCommentedRecordError.JsonError;
        };
        defer parsed.deinit();
        const value = parsed.value;
        if (value.success == false) {
            return GetCommentedRecordError.SuccessError;
        } else if (value.result.len != 1) {
            return GetCommentedRecordError.MultipleRecordsError;
        } else {
            const rec = value.result[0];
            return DNSRecord{
                .content = try std.fmt.allocPrint(allocator, "{s}", .{rec.content}),
                .id = try std.fmt.allocPrint(allocator, "{s}", .{rec.id}),
                .name = try std.fmt.allocPrint(allocator, "{s}", .{rec.name}),
                .zone_id = try std.fmt.allocPrint(allocator, "{s}", .{zone_id}),
            };
        }
    }
}

const PatchRecordResult = struct {
    success: bool,
    result: ListRecordsResultRecord,
};

pub const PatchRecordError = error{
    StatusError,
    SuccessError,
    HttpClientError,
    JsonError,
} || std.fmt.AllocPrintError;

pub fn PatchRecord(
    allocator: std.mem.Allocator,
    token: []const u8,
    zone_id: []const u8,
    record_id: []const u8,
    ip: []const u8,
    proxied: bool,
) PatchRecordError!void {
    const authorization = try std.fmt.allocPrint(allocator, "Bearer {s}", .{token});
    defer allocator.free(authorization);

    const url = try std.fmt.allocPrint(
        allocator,
        "https://api.cloudflare.com/client/v4/zones/{s}/dns_records/{s}",
        .{ zone_id, record_id },
    );
    defer allocator.free(url);

    const headers = &[_]std.http.Header{
        .{ .name = "Authorization", .value = authorization },
        .{ .name = "Content-Type", .value = "application/json" },
    };

    var client = std.http.Client{
        .allocator = allocator,
    };
    defer client.deinit();

    var response = std.ArrayList(u8).init(allocator);
    defer response.deinit();

    const proxied_str = if (proxied) "true" else "false";
    const payload = try std.fmt.allocPrint(
        allocator,
        "{{ \"content\": \"{s}\",\"proxied\": {s} }}",
        .{ ip, proxied_str },
    );
    defer allocator.free(payload);

    const result = client.fetch(.{
        .method = .PATCH,
        .location = .{
            .url = url,
        },
        .extra_headers = headers,
        .response_storage = .{
            .dynamic = &response,
        },
        .payload = payload,
    }) catch |err| {
        switch (err) {
            std.mem.Allocator.Error.OutOfMemory => return PatchRecordError.OutOfMemory,
            else => {
                log.err("Http client error: {s}", .{@errorName(err)});
                return PatchRecordError.HttpClientError;
            },
        }
    };

    log.debug("Result: {d}", .{result.status});
    log.debug("Response: {s}", .{response.items});

    if (result.status != .ok) {
        return PatchRecordError.StatusError;
    } else {
        const parsed = std.json.parseFromSlice(
            PatchRecordResult,
            allocator,
            response.items,
            .{
                .ignore_unknown_fields = true,
            },
        ) catch |err| {
            log.err("Json error: {s}", .{@errorName(err)});
            return PatchRecordError.JsonError;
        };
        defer parsed.deinit();
        const value = parsed.value;
        if (value.success == false) {
            return PatchRecordError.SuccessError;
        }
    }
}

const GetCurrentIpResult = struct {
    ip: []const u8,

    pub fn deinit(self: GetCurrentIpResult, allocator: std.mem.Allocator) void {
        allocator.free(self.ip);
    }
};

pub const GetCurrentIpError = error{
    StatusError,
    ParseError,
    HttpClientError,
} || std.fmt.AllocPrintError;

const NEEDLE = "ip=";
pub fn GetCurrentIp(allocator: std.mem.Allocator) GetCurrentIpError!GetCurrentIpResult {
    var client = std.http.Client{
        .allocator = allocator,
    };
    defer client.deinit();

    var response = std.ArrayList(u8).init(allocator);
    defer response.deinit();

    const result = client.fetch(.{
        .method = .GET,
        .location = .{
            .url = "https://cloudflare.com/cdn-cgi/trace",
        },
        .response_storage = .{
            .dynamic = &response,
        },
    }) catch |err| {
        switch (err) {
            std.mem.Allocator.Error.OutOfMemory => return GetCurrentIpError.OutOfMemory,
            else => {
                log.err("Http client error: {s}", .{@errorName(err)});
                return GetCurrentIpError.HttpClientError;
            },
        }
    };

    log.debug("Result: {d}", .{result.status});
    log.debug("Response: {s}", .{response.items});

    if (result.status != .ok) {
        return GetCurrentIpError.StatusError;
    } else {
        const txt = response.items;
        const ip_start = std.mem.indexOf(u8, txt, NEEDLE) orelse return GetCurrentIpError.ParseError;
        const ip_end = std.mem.indexOf(u8, txt[ip_start..], "\n") orelse return GetCurrentIpError.ParseError;
        log.debug("start: {d}, end: {d}", .{ ip_start, ip_end });
        const ip = txt[ip_start + NEEDLE.len .. ip_start + ip_end];
        log.debug("ip: {s}", .{ip});
        return GetCurrentIpResult{
            .ip = try std.fmt.allocPrint(allocator, "{s}", .{ip}),
        };
    }
}
