package com.apparence.camerawesome.models;

import java.util.List;
import java.util.Set;

public class MultiCamera {

    private String logicCameraId;

    private Set<String> physicsCameraIds;

    public MultiCamera(String logicCameraId, Set<String> physicsCameraIds) {
        this.logicCameraId = logicCameraId;
        this.physicsCameraIds = physicsCameraIds;
    }

    public String getLogicCameraId() {
        return logicCameraId;
    }

    public Set<String> getPhysicsCameraIds() { return physicsCameraIds; }
}