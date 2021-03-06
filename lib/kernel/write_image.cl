/* OpenCL built-in library: write_image()

   Copyright (c) 2013 Ville Korhonen 
   
   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:
   
   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.
   
   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
   THE SOFTWARE.
*/

#include "templates.h"
#include "pocl_image_rw_utils.h"

#if (__clang_major__ > 3) || ((__clang_major__ == 3) && (__clang_minor__ >= 5))
// Clang 3.5 crashes in case trying to cast to the private pointer,
// adding the global qualifier fixes it. Clang 3.4 crashes if it's
// there. The issue is in SROA.
#define ADDRESS_SPACE global
#else
#define ADDRESS_SPACE
#endif

// 3.9 needs access qualifier
// TODO: rw images
#ifdef CLANG_OLDER_THAN_3_9
#define IMG_WRITE_AQ
#else
#define IMG_WRITE_AQ __write_only
#endif

/* writes pixel to coord in image */
void pocl_write_pixel (void* color_, ADDRESS_SPACE dev_image_t* dev_image,
                       int4 coord)
{
  uint4 *color = (uint4*)color_;
  int width = dev_image->_width;
  int height = dev_image->_height;
  int num_channels = dev_image->_num_channels;
  int i = num_channels;
  int elem_size = dev_image->_elem_size;
  int const base_index =
    (coord.x + coord.y*width + coord.z*height*width) * num_channels;

  if (dev_image->_order == CL_A)
    {
      if (elem_size == 1)
        ((uchar*) (dev_image->_data))[base_index] = (*color)[3];
      else if (elem_size == 2)
        ((ushort*) (dev_image->_data))[base_index] = (*color)[3];
      else if (elem_size == 4)
        ((uint*) (dev_image->_data))[base_index] = (*color)[3];
      return;
    }

  if (elem_size == 1)
    {
      while (i--)
        {
          ((uchar*) (dev_image->_data))[base_index + i] = (*color)[i];
        }
    }
  else if (elem_size == 2)
    {
      while (i--)
        {
          ((ushort*) dev_image->_data)[base_index + i] = (*color)[i];
        }
    }
  else if (elem_size == 4)
    {
      while (i--)
        {
          ((uint*) dev_image->_data)[base_index + i] = (*color)[i];
        }
    }
}

/* Implementation for write_image with any image data type and int coordinates
   __IMGTYPE__ = image type (image2d_t, ...)
   __DTYPE__  = data type to be read (int4 or uint4 float4)
   __POSTFIX__ = function name postfix (i, ui, f)
   __COORD__   = coordinate type (int, int2, int4)
*/
#define IMPLEMENT_WRITE_IMAGE_INT_COORD(__IMGTYPE__,__DTYPE__,__POSTFIX__, \
                                        __COORD__)                      \
  void _CL_OVERLOADABLE write_image##__POSTFIX__ (__write_only __IMGTYPE__ image,    \
                                                  __COORD__ coord,      \
                                                  __DTYPE__ color)      \
  {                                                                     \
    int4 coord4;                                                        \
    INITCOORD##__COORD__(coord4, coord);                                \
    global dev_image_t* i_ptr = __builtin_astype (image, global dev_image_t*); \
    pocl_write_pixel (&color, i_ptr, coord4);                             \
  }                                                                     \

IMPLEMENT_WRITE_IMAGE_INT_COORD (image2d_t, uint4, ui, int2)
IMPLEMENT_WRITE_IMAGE_INT_COORD (image2d_t, float4, f, int2)
IMPLEMENT_WRITE_IMAGE_INT_COORD (image3d_t, float4, f, int4)
