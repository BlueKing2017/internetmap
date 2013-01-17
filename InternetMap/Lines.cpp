//
//  Lines.cpp
//  InternetMap
//

#include "OpenGL.hpp"
#include "Lines.hpp"
#include "Program.hpp"
#include <stdlib.h>

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

struct LineVertex {
    RawVector3 position;
    ByteColor color;
};

Lines::Lines(int initialCount) :
    _width(1.0f),
    _count(initialCount),
    _vertexBuffer(0),
    _lockedVertices(0)
{
    // set up vertex buffer state
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, _count * 2 * sizeof(LineVertex), NULL, GL_DYNAMIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
}

Lines::~Lines() {
    if(!gHasMapBuffer && _lockedVertices) {
        delete _lockedVertices;
    }

    glDeleteBuffers(1, &_vertexBuffer);
}

void Lines::beginUpdate() {
    if(gHasMapBuffer ) {
        if(!_lockedVertices) {
            glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
            _lockedVertices = (LineVertex*)glMapBufferOES(GL_ARRAY_BUFFER, GL_WRITE_ONLY_OES);
        }
    }
    else {
        if(!_lockedVertices) {
            _lockedVertices = new LineVertex[_count * 2];
        }
    }
}

void Lines::endUpdate() {
    if(gHasMapBuffer ) {
        _lockedVertices = NULL;
        glUnmapBufferOES(GL_ARRAY_BUFFER);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }
    else {
        glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
        glBufferData(GL_ARRAY_BUFFER, _count * 2 * sizeof(LineVertex), _lockedVertices, GL_DYNAMIC_DRAW);
        glBindBuffer(GL_ARRAY_BUFFER, 0);
    }
}

void Lines::updateLine(int index, const Point3& start, const Color& startColor, const Point3& end, const Color& endColor) {
    if(index >= _count) {
        return;
    }
    
    LineVertex* vert0 = &_lockedVertices[index * 2];
    LineVertex* vert1 = &_lockedVertices[index * 2 + 1];
    
    vert0->position = start;
    vert0->color = startColor;
    
    vert1->position = end;
    vert1->color = endColor;
}


void Lines::display(void) {
    glLineWidth(_width);

    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);

    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, sizeof(LineVertex), BUFFER_OFFSET(0));
    
    glEnableVertexAttribArray(ATTRIB_COLOR);
    glVertexAttribPointer(ATTRIB_COLOR, 4, GL_UNSIGNED_BYTE, GL_TRUE, sizeof(LineVertex), BUFFER_OFFSET(sizeof(float) * 3));
    
    glDrawArrays(GL_LINES, 0, _count * 2);
    
    glDisableVertexAttribArray(ATTRIB_VERTEX);
    glDisableVertexAttribArray(ATTRIB_COLOR);
    glBindBuffer(GL_ARRAY_BUFFER, 0);

}
