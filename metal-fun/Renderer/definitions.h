//
//  definitions.h
//  metal-fun
//
//  Created by Frank Baiata on 1/22/25.
//

#ifndef definitions_h
#define definitions_h

#include <simd/simd.h>

typedef enum MetalVertexInputIndex
{
    MetalVertexInputIndexVertices     = 0,
    MetalVertexInputIndexViewportSize = 1,
} MetalVertexInputIndex;

typedef struct
{
    vector_float2 position;
    vector_float4 color;
    
} MetalVertex;


#endif
