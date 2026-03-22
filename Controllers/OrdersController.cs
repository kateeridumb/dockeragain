using CosmeticShopAPI.DTOs;
using CosmeticShopAPI.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace CosmeticShopAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class OrdersController : ControllerBase
    {
        private readonly CosmeticsShopDbContext _context;

        public OrdersController(CosmeticsShopDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<IEnumerable<OrderDTO>>> GetOrders()
        {
            var orders = await _context.Orders.ToListAsync();

            var dtos = orders.Select(o => new OrderDTO
            {
                IdOrder = o.Id_Order,
                UserId = o.UserID,
                OrderDate = o.OrderDate,
                TotalAmount = o.TotalAmount,
                StatusOr = o.StatusOr,
                DeliveryAddress = o.DeliveryAddress,
                PromoId = o.PromoID,
            }).ToList();

            return Ok(dtos);
        }

        [HttpGet("user/{userId}")]
        public async Task<ActionResult<IEnumerable<OrderDTO>>> GetUserOrders(int userId)
        {
            var orders = await _context.Orders
                .Where(o => o.UserID == userId)
                .OrderByDescending(o => o.OrderDate)
                .ToListAsync();

            var dtos = orders.Select(o => new OrderDTO
            {
                IdOrder = o.Id_Order,
                UserId = o.UserID,
                OrderDate = o.OrderDate,
                TotalAmount = o.TotalAmount,
                StatusOr = o.StatusOr,
                DeliveryAddress = o.DeliveryAddress,
                PromoId = o.PromoID,
            }).ToList();

            return Ok(dtos);
        }

        [HttpGet("{id}")]
        public async Task<ActionResult<OrderDTO>> GetOrder(int id)
        {
            var order = await _context.Orders
                .FirstOrDefaultAsync(o => o.Id_Order == id);

            if (order == null)
                return NotFound();

            var dto = new OrderDTO
            {
                IdOrder = order.Id_Order,
                UserId = order.UserID,
                OrderDate = order.OrderDate,
                TotalAmount = order.TotalAmount,
                StatusOr = order.StatusOr,
                DeliveryAddress = order.DeliveryAddress,
                PromoId = order.PromoID,
            };

            return Ok(dto);
        }

        [HttpPost]
        public async Task<ActionResult<OrderDTO>> PostOrder([FromBody] OrderDTO orderDto)
        {
            try
            {
                Console.WriteLine($"Получен заказ: UserId={orderDto.UserId}, TotalAmount={orderDto.TotalAmount}");

                if (orderDto.UserId <= 0)
                {
                    return BadRequest("UserId должен быть больше 0");
                }

                var statusOr = orderDto.StatusOr ?? "В обработке";
                var deliveryAddress = orderDto.DeliveryAddress ?? "";
                if (orderDto.PromoId.HasValue && orderDto.PromoId.Value > 0)
                {
                    var insertSql = @"
                INSERT INTO Orders (UserID, OrderDate, TotalAmount, StatusOr, DeliveryAddress, PromoID)
                VALUES ({0}, GETDATE(), {1}, {2}, {3}, {4})";

                    await _context.Database.ExecuteSqlRawAsync(insertSql,
                        orderDto.UserId,
                        orderDto.TotalAmount,
                        statusOr,
                        deliveryAddress,
                        orderDto.PromoId.Value);
                }
                else
                {
                    var insertSql = @"
                INSERT INTO Orders (UserID, OrderDate, TotalAmount, StatusOr, DeliveryAddress, PromoID)
                VALUES ({0}, GETDATE(), {1}, {2}, {3}, NULL)";

                    await _context.Database.ExecuteSqlRawAsync(insertSql,
                        orderDto.UserId,
                        orderDto.TotalAmount,
                        statusOr,
                        deliveryAddress);
                }

                var newId = await _context.Orders
                    .Where(o => o.UserID == orderDto.UserId && o.TotalAmount == orderDto.TotalAmount && o.StatusOr == statusOr)
                    .OrderByDescending(o => o.OrderDate)
                    .ThenByDescending(o => o.Id_Order)
                    .Select(o => o.Id_Order)
                    .FirstAsync();


                orderDto.IdOrder = newId;

                Console.WriteLine($"Заказ создан с ID: {newId}");
                return CreatedAtAction(nameof(GetOrder), new { id = orderDto.IdOrder }, orderDto);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка при создании заказа: {ex.Message}");
                Console.WriteLine($"StackTrace: {ex.StackTrace}");
                return BadRequest($"Ошибка при создании заказа: {ex.Message}");
            }
        }

        [HttpPut("{id}")]
        public async Task<IActionResult> PutOrder(int id, Order order)
        {

            var sql = @"
             UPDATE Orders
             SET UserID = {0}, OrderDate = {1}, TotalAmount = {2},
                 StatusOr = {3}, DeliveryAddress = {4}, PromoID = {5}
             WHERE Id_Order = {6}";

            var rows = await _context.Database.ExecuteSqlRawAsync(sql,
                order.UserID,
                order.OrderDate,
                order.TotalAmount,
                order.StatusOr,
                order.DeliveryAddress,
                order.PromoID,
                id);

            if (rows == 0)
                return NotFound();

            return NoContent();
        }


        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteOrder(int id)
        {
            try
            {
                var deleteDetailsSql = "DELETE FROM OrderDetails WHERE OrderID = {0}";
                await _context.Database.ExecuteSqlRawAsync(deleteDetailsSql, id);

                var sql = "DELETE FROM Orders WHERE Id_Order = {0}";
                var rows = await _context.Database.ExecuteSqlRawAsync(sql, id);

                if (rows == 0)
                    return NotFound();

                return NoContent();
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Ошибка при удалении заказа: {ex.Message}");
                return BadRequest($"Ошибка при удалении заказа: {ex.Message}");
            }
        }


    }
}
