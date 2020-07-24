// ----------------------------------------------------------------------------
// -                        Open3D: www.open3d.org                            -
// ----------------------------------------------------------------------------
// The MIT License (MIT)
//
// Copyright (c) 2018 www.open3d.org
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.
// ----------------------------------------------------------------------------

#include <stdio.h>
#include <stdlib.h>

#include "open3d/core/op/linalg/Inverse.h"
#include "open3d/core/op/linalg/LinalgUtils.h"

namespace open3d {
namespace core {

void InverseCUDA(void* A_data,
                 void* ipiv_data,
                 void* output_data,
                 int n,
                 Dtype dtype,
                 const Device& device) {
    cusolverDnHandle_t handle = CuSolverContext::GetInstance()->GetHandle();
    int* dinfo = static_cast<int*>(MemoryManager::Malloc(sizeof(int), device));
    int len;

    switch (dtype) {
        case Dtype::Float32: {
            OPEN3D_CUSOLVER_CHECK(
                    cusolverDnSgetrf_bufferSize(handle, n, n, NULL, n, &len),
                    "[InverseCUDA] cusolverDnSgetrf_bufferSize failed");
            void* workspace =
                    MemoryManager::Malloc(len * sizeof(float), device);

            OPEN3D_CUSOLVER_CHECK_WITH_DINFO(
                    cusolverDnSgetrf(handle, n, n, static_cast<float*>(A_data),
                                     n, static_cast<float*>(workspace),
                                     static_cast<int*>(ipiv_data), dinfo),
                    "[InverseCUDA] cusolverDnSgetrf failed with dinfo = ",
                    dinfo, device);

            OPEN3D_CUSOLVER_CHECK_WITH_DINFO(
                    cusolverDnSgetrs(handle, CUBLAS_OP_N, n, n,
                                     static_cast<float*>(A_data), n,
                                     static_cast<int*>(ipiv_data),
                                     static_cast<float*>(output_data), n,
                                     dinfo),
                    "[InverseCUDA] cusolverDnSgetrs failed with dinfo = ",
                    dinfo, device);

            MemoryManager::Free(workspace, device);
            break;
        }

        case Dtype::Float64: {
            OPEN3D_CUSOLVER_CHECK(
                    cusolverDnDgetrf_bufferSize(handle, n, n, NULL, n, &len),
                    "[InverseCUDA] cusolverDnDgetrf_bufferSize failed");
            void* workspace =
                    MemoryManager::Malloc(len * sizeof(double), device);

            OPEN3D_CUSOLVER_CHECK_WITH_DINFO(
                    cusolverDnDgetrf(handle, n, n, static_cast<double*>(A_data),
                                     n, static_cast<double*>(workspace),
                                     static_cast<int*>(ipiv_data), dinfo),
                    "[InverseCUDA] cusolverDnDgetrf failed with dinfo = ",
                    dinfo, device);

            OPEN3D_CUSOLVER_CHECK_WITH_DINFO(
                    cusolverDnDgetrs(handle, CUBLAS_OP_N, n, n,
                                     static_cast<double*>(A_data), n,
                                     static_cast<int*>(ipiv_data),
                                     static_cast<double*>(output_data), n,
                                     dinfo),
                    "[InverseCUDA] cusolverDnDgetrs failed with dinfo = ",
                    dinfo, device);

            MemoryManager::Free(workspace, device);
            break;
        }
        default: {  // should never reach here
            utility::LogError("Unsupported dtype {} in InverseCUDA.",
                              DtypeUtil::ToString(dtype));
        }
    }

    MemoryManager::Free(dinfo, device);
}

}  // namespace core
}  // namespace open3d
