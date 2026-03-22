using CosmeticShopAPI.Models;
using InfluxDB.Client;
using InfluxDB.Client.Api.Domain;
using Microsoft.EntityFrameworkCore;

namespace CosmeticShopAPI.Services
{
    public interface IInfluxMetricsService
    {
        Task UpdateMetricsAsync();
    }

    public class InfluxMetricsService : IInfluxMetricsService
    {
        private readonly CosmeticsShopDbContext _context;
        private readonly ILogger<InfluxMetricsService> _logger;
        private readonly InfluxDBClient _client;

        private readonly string _bucket;
        private readonly string _org;

        public InfluxMetricsService(
            CosmeticsShopDbContext context,
            ILogger<InfluxMetricsService> logger,
            IConfiguration configuration)
        {
            _context = context;
            _logger = logger;

            string influxUrl = configuration["InfluxDB:Url"];
            string token = configuration["InfluxDB:Token"];

            _bucket = configuration["InfluxDB:Bucket"];
            _org = configuration["InfluxDB:Org"];

            _client = InfluxDBClientFactory.Create(influxUrl, token);
        }

        public async Task UpdateMetricsAsync()
        {
            try
            {
                var write = _client.GetWriteApiAsync();

                await WriteUsersByRole(write);
                await WriteProductsByCategory(write);
                await WriteOrdersByUser(write);

                _logger.LogInformation("InfluxDB метрики (Line Protocol) записаны.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Ошибка записи Line Protocol в InfluxDB");
            }
        }

        private async Task WriteUsersByRole(WriteApiAsync write)
        {
            var users = _context.Users
                .GroupBy(u => u.RoleUs)
                .Select(g => new { Role = g.Key ?? "unknown", Count = g.Count() })
                .ToList();

            long ts = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() * 1_000_000;

            foreach (var u in users)
            {
                string lp =
                    $"users_by_role,role={EscapeTag(u.Role)} count={u.Count}i {ts}";

                await write.WriteRecordAsync(lp, WritePrecision.Ns, _bucket, _org);
            }
        }

        private async Task WriteProductsByCategory(WriteApiAsync write)
        {
            var categories = _context.Categories.ToList();

            var data = _context.Products
                .GroupBy(p => p.CategoryID)
                .Select(g => new { CategoryId = g.Key, Count = g.Count() })
                .ToList();

            long ts = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() * 1_000_000;

            foreach (var c in data)
            {
                string name = categories.FirstOrDefault(x => x.Id_Category == c.CategoryId)?.NameCa
                              ?? "Без категории";

                string lp =
                    $"products_by_category,category={EscapeTag(name)} count={c.Count}i {ts}";

                await write.WriteRecordAsync(lp, WritePrecision.Ns, _bucket, _org);
            }
        }

        private async Task WriteOrdersByUser(WriteApiAsync write)
        {
            var orders = _context.Orders
                .GroupBy(o => o.UserID)
                .Select(g => new { UserId = g.Key.ToString(), Count = g.Count() })
                .ToList();

            long ts = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() * 1_000_000;

            foreach (var o in orders)
            {
                string lp =
                    $"orders_by_user,userId={EscapeTag(o.UserId)} count={o.Count}i {ts}";

                await write.WriteRecordAsync(lp, WritePrecision.Ns, _bucket, _org);
            }
        }

        private string EscapeTag(string value)
        {
            return value
                .Replace(" ", "\\ ")
                .Replace(",", "\\,")
                .Replace("=", "\\=");
        }
    }
}
