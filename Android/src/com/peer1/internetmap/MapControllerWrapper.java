package com.peer1.internetmap;

public class MapControllerWrapper {
    public native void rotateRadiansXY(float radX, float radY);
    public native void startMomentumPanWithVelocity(float vX, float vY);
    public native void handleTouchDownAtPoint(float x, float y);
    public native void zoomByScale(float scale);
    public native void startMomentumZoomWithVelocity(float velocity);
    public native void rotateRadiansZ(float radians);
    public native void startMomentumRotationWithVelocity(float velocity);
    public native boolean selectHoveredNode();
    public native NodeWrapper nodeAtIndex(int index);
    public native int targetNodeIndex();
    public native NodeWrapper nodeByAsn(String asn);
    public native void updateTargetForIndex(int index);
    public native int nodeCount();

}
