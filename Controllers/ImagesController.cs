using CosmeticShopAPI.DTOs;
using CosmeticShopAPI.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace CosmeticShopAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ImagesController : ControllerBase
    {
        private readonly CosmeticsShopDbContext _context;

        public ImagesController(CosmeticsShopDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        public async Task<ActionResult<ApiResponse<IEnumerable<ImageDTO>>>> GetImages()
        {
            try
            {
                var images = await _context.Images.ToListAsync();

                var imageDtos = images.Select(i => new ImageDTO
                {
                    ID_Image = i.ID_Image,
                    ProductID = i.ProductID,
                    ImageURL = i.ImageURL,
                    DescriptionIMG = i.DescriptionIMG
                }).ToList();

                var response = new ApiResponse<IEnumerable<ImageDTO>>
                {
                    Success = true,
                    Data = imageDtos
                };

                return Ok(response);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new ApiResponse<string>
                {
                    Success = false,
                    Message = $"Ошибка при загрузке изображений: {ex.Message}"
                });
            }
        }

        [HttpGet("product/{productId}")]
        public async Task<ActionResult<ApiResponse<IEnumerable<ImageDTO>>>> GetImagesByProduct(int productId)
        {
            try
            {
                var images = await _context.Images
                    .Where(i => i.ProductID == productId)
                    .ToListAsync();

                var imageDtos = images.Select(i => new ImageDTO
                {
                    ID_Image = i.ID_Image,
                    ProductID = i.ProductID,
                    ImageURL = i.ImageURL,
                    DescriptionIMG = i.DescriptionIMG
                }).ToList();

                var response = new ApiResponse<IEnumerable<ImageDTO>>
                {
                    Success = true,
                    Data = imageDtos
                };

                return Ok(response);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new ApiResponse<string>
                {
                    Success = false,
                    Message = $"Ошибка при загрузке изображений товара: {ex.Message}"
                });
            }
        }

        [HttpPost]
        public async Task<ActionResult<Image>> PostImage(Image image)
        {
            try
            {
                var sql = @"
                    INSERT INTO Images (ProductID, ImageURL, DescriptionIMG)
                    VALUES ({0}, {1}, {2})";

                await _context.Database.ExecuteSqlRawAsync(sql,
                    image.ProductID,
                    image.ImageURL,
                    image.DescriptionIMG);

                var newId = await _context.Images.MaxAsync(i => (int?)i.ID_Image) ?? 0;
                image.ID_Image = newId;

                return CreatedAtAction(nameof(GetImagesByProduct), new { productId = image.ProductID }, image);
            }
            catch (Exception ex)
            {
                return StatusCode(500, new ApiResponse<string>
                {
                    Success = false,
                    Message = $"Ошибка при создании изображения: {ex.Message}"
                });
            }
        }
    }
}