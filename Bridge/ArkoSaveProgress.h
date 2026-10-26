//  ArkoSaveProgress.h
//  保存进度/取消的公共桥接（内部头，仅 .mm 引用，不进 bridging header）。
//  把 SDK 的 IPDF_Progress / IPDF_Pause 转发到 block，供 ArkoDocument / ArkoPhotoBook 共用。

#import <Foundation/Foundation.h>
#include "ipdf_base.h"

/// 进度回调接收器：block 在「保存线程」同步调用，Swift 侧需自行派发到主线程。
@interface ArkoProgressSink : NSObject
/// 进度回调（0.0~1.0）。
@property (nonatomic, copy, nullable) void (^onProgress)(float);
/// 取消回调（返回 YES 表示取消）；为 nil 表示不可取消。
@property (nonatomic, copy, nullable) BOOL (^onCancel)(void);
@end

/// 暂停：始终不暂停（保存跑在后台线程，无需让出主线程）。
class ArkoSavePause : public IPDF_Pause {
public:
    int NeedToPause() override { return 0; }
};

/// 进度：把 SetRange/SetCurPos 归一化到 0..1 转发给 sink；IsCancel 转问 sink.onCancel。
class ArkoSaveProgress : public IPDF_Progress {
public:
    __unsafe_unretained ArkoProgressSink *sink;
    float _min = 0, _max = 1;

    int IsCancel() override {
        if (sink && sink.onCancel && sink.onCancel()) {
            return 1;
        }
        return 0;
    }
    void SetRange(float min, float max) override { _min = min; _max = max; }
    void SetCurPos(float pos) override {
        if (sink && sink.onProgress && _max > _min) {
            float p = (pos - _min) / (_max - _min);
            if (p < 0.f) p = 0.f;
            if (p > 1.f) p = 1.f;
            sink.onProgress(p);
        }
    }
};
