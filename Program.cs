using CosmeticShopAPI.Models;
using CosmeticShopAPI.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Prometheus;
using System.Linq;
using System.Text;
using System.Text.Json.Serialization;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles;
        options.JsonSerializerOptions.WriteIndented = true;
    })
    .ConfigureApiBehaviorOptions(options =>
    {
        options.InvalidModelStateResponseFactory = context =>
        {
            var errors = context.ModelState
                .Where(x => x.Value?.Errors.Count > 0)
                .ToDictionary(
                    kvp => kvp.Key,
                    kvp => kvp.Value.Errors.Select(e =>
                        !string.IsNullOrEmpty(e.ErrorMessage)
                            ? e.ErrorMessage
                            : "Неверное значение").ToArray()
                );

            return new BadRequestObjectResult(new
            {
                type = "https://tools.ietf.org/html/rfc9110#section-15.5.1",
                title = "Произошла одна или несколько ошибок валидации.",
                status = 400,
                errors = errors,
                traceId = context.HttpContext.TraceIdentifier
            });
        };
    });

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

builder.Services.AddDbContext<CosmeticsShopDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(builder.Configuration["Jwt:Secret"])),
            ValidateIssuer = false,
            ValidateAudience = false,
            ValidateLifetime = true,
            ClockSkew = TimeSpan.Zero
        };
    });

builder.Services.AddAuthorization();

builder.Services.AddScoped<TokenService>();
builder.Services.AddScoped<BusinessMetricsService>();
builder.Services.AddScoped<IEmailService, EmailService>();
builder.Services.AddScoped<IInfluxMetricsService, InfluxMetricsService>();


var app = builder.Build();

_ = Task.Run(async () =>
{
    var timer = new PeriodicTimer(TimeSpan.FromSeconds(30));

    while (await timer.WaitForNextTickAsync())
    {
        using var scope = app.Services.CreateScope();
        var influx = scope.ServiceProvider.GetRequiredService<IInfluxMetricsService>();

        await influx.UpdateMetricsAsync();
    }
});

Task.Run(async () =>
{
    while (true)
    {
        using var scope = app.Services.CreateScope();
        var metricsService = scope.ServiceProvider.GetRequiredService<BusinessMetricsService>();
        var logger = scope.ServiceProvider.GetRequiredService<ILogger<Program>>();

        try
        {
            metricsService.UpdateMetrics();
            logger.LogInformation("������� ��������� �������");
        }
        catch (Exception ex)
        {
            logger.LogError(ex, "������ � ���������� ������");
        }

        await Task.Delay(TimeSpan.FromSeconds(30));
    }
});

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();

app.UseAuthentication();
app.UseAuthorization();

app.UseHttpMetrics();
app.MapMetrics();
app.MapControllers();



app.Run();
