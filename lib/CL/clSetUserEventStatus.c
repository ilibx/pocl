#include "pocl_cl.h"
CL_API_ENTRY cl_int CL_API_CALL
clSetUserEventStatus(cl_event    event ,
                     cl_int      execution_status ) CL_API_SUFFIX__VERSION_1_1
{
  POCL_ABORT_UNIMPLEMENTED();
  return CL_SUCCESS;
}
