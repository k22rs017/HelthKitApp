import SwiftUI
import HealthKit

struct ContentView: View {
    // HealthStoreのインスタンスを作成
    private var healthStore = HKHealthStore()
    // 心拍数の単位を設定
    let heartRateQuantity = HKUnit(from: "count/min")
    
    // 表示する心拍数の状態変数
    @State private var value = 0
    // アニメーション速度の状態変数
    @State private var animationSpeed: Double = 1.0
    // アニメーション状態を管理するフラグ
    @State private var isAnimating = false

    var body: some View {
        VStack {
            HStack {
                // ハートアイコンを表示
                Text("🫀")
                    .font(.system(size: 50))  // フォントサイズを50に設定
                    .scaleEffect(isAnimating ? 1.2 : 1.0)  // アニメーションによる拡大縮小
                    .animation(
                        Animation.easeInOut(duration: animationSpeed)
                            .repeatForever(autoreverses: true),  // アニメーションの繰り返し設定
                        value: isAnimating
                    )
                    .onAppear {
                        self.isAnimating = true  // ビューが表示されたときにアニメーションを開始
                    }
                Spacer()
            }
            
            HStack {
                // 心拍数を表示
                Text("\(value)")
                    .fontWeight(.regular)  // フォントの重さを通常に設定
                    .font(.system(size: 50))  // フォントサイズを70に設定
                
                // "BPM"テキストを表示
                Text("BPM")
                    .font(.headline)  // フォントを見出しスタイルに設定
                    .fontWeight(.bold)  // フォントの重さを太字に設定
                    .foregroundColor(Color.red)  // テキストの色を赤に設定
                    .padding(.bottom, 28.0)  // 下部に28ポイントのパディングを追加
                
                Spacer()
            }
        }
        .padding()  // 全体にパディン‹グを追加
        .onAppear(perform: start)  // ビューが表示されたときにstartメソッドを実行
    }

    func start() {
        authorizeHealthKit()  // HealthKitの認証を開始
        startHeartRateQuery(quantityTypeIdentifier: .heartRate)  // 心拍数クエリを開始
    }
    
    func authorizeHealthKit() {
        // 読み取り権限を要求するためのHealthKitタイプのセットを作成
        let healthKitTypes: Set = [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        ]

        // 認証を要求
        healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { success, error in
            if !success {
                // エラー処理をここで行う
            }
        }
    }
    
    private func startHeartRateQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier) {
        // ローカルデバイスからのデータをフィルタリングする述語
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])

        // データが更新されたときのハンドラ
        let updateHandler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = {
            query, samples, deletedObjects, queryAnchor, error in
            
            // 取得したサンプルを処理
            guard let samples = samples as? [HKQuantitySample] else {
                return
            }
            
            self.process(samples, type: quantityTypeIdentifier)
        }
        
        // 心拍数データを取得するクエリを作成
        let query = HKAnchoredObjectQuery(
            type: HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier)!,  // クエリのタイプを設定
            predicate: devicePredicate,  // フィルタリングの述語を設定
            anchor: nil,  // アンカーを設定しない
            limit: HKObjectQueryNoLimit,  // 取得するデータの上限を設定しない
            resultsHandler: updateHandler  // 結果を処理するハンドラを設定
        )
        
        query.updateHandler = updateHandler  // 更新ハンドラを設定
        healthStore.execute(query)  // クエリを実行
    }
    
    private func process(_ samples: [HKQuantitySample], type: HKQuantityTypeIdentifier) {
        // 最新のサンプルを取得
        guard let lastSample = samples.last else { return }
        let lastHeartRate = lastSample.quantity.doubleValue(for: heartRateQuantity)
        
        // メインスレッドでUIを更新
        DispatchQueue.main.async {
            self.value = Int(lastHeartRate)  // 心拍数を更新
            
            // 心拍数に基づいてアニメーション速度を調整
            self.animationSpeed = max(0.1, 60.0 / lastHeartRate)
            self.isAnimating = true  // アニメーションを開始
        }
    }
}

#Preview {
    ContentView()  // プレビューでContentViewを表示
}
