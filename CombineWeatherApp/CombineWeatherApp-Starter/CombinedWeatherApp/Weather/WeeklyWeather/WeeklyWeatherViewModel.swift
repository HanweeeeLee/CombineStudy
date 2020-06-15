/// Copyright (c) 2019 Razeware LLC
/// 
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
/// 
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
/// 
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
/// 
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import SwiftUI
import Combine

//1 WeeklyWeatherViewModel이 ObservableObject와 Identifiable을 준수하도록 만듭니다. 이것을 준수하면 WeeklyWeatherViewModel의 프로퍼티가 바인딩(bindings)을 사용할 수 있다는 의미입니다. View 레이어에 오면 만드는 방법을 볼 수 있을 것입니다.
class WeeklyWeatherViewModel: ObservableObject, Identifiable {
  //2 제대로된 @Published 수정자 위임(delegate)은city 프로퍼티를 관찰(observe)하는 것이 가능하도록 만듭니다. 이를 활용하는 방법은 잠시 뒤에 보게 될 것입니다.
  @Published var city:String = "" {
    didSet {
      print("city :\(city)")
    }
  }
  //3 ViewModel에 있는 View의 데이터 소스를 유지할 것입니다. 이것은 MVC에서 사용했던 것과는 대조적입니다. 왜냐하면 그 프로퍼티는 @Published로 표시 되었기 때문에, 컴파일러는 자동으로 게시자(publisher)를 합성(synthsizes) 합니다. SwiftUI는 해당 게시자(publisher)를 구독(subscribes)하고 프로퍼티가 변할때 화면을 다시 그려줍니다.
  @Published var dataSource:[DailyWeatherRowViewModel] = []
  
  private let weatherFetcher: WeatherFetchable
  
  //4 요청에 대한 참조 집합으로 disposables을 사용합니다. 해당 참조를 유지할 필요없이, 네트워크 요청이 계속 유지하지 않을 것이며, 서버로부터 응답 받지 못하게 할 것입니다.
  private var disposables = Set<AnyCancellable>()
  
//  init(weatherFetcher: WeatherFetchable) {
//    self.weatherFetcher = weatherFetcher
//  }
  
  //이 코드는 두 세계(SwiftUI와 Combine)를 연결하기 때문에 중요합니다:
  // 1 scheduler 매개변수를 추가해서, HTTP 요청에서 사용할 큐(queue)를 지정할 수 있습니다.
  init( weatherFetcher: WeatherFetchable, scheduler: DispatchQueue = DispatchQueue(label: "WeatherViewModel") ) {
    self.weatherFetcher = weatherFetcher
    // 2 city 프로퍼티는 @Published 프로퍼티 델리게이터를 사용므로 다른 Publisher와 같은 역할을 합니다. 이것은 관찰될(observed)수 있고 Publiser에서 사용할 수 있는 다른 메소드를 사용할 수 있다는 의미입니다.
    _ = $city
    // 3 관찰(observation)을 만들자마자, $city는 첫번째 값을 내보냅니다. 첫번째 값이 빈 문자열이므로, 의도하지 않는 네트워크 호출을 피하려면 그것을 건너뛰어야 합니다.
      .dropFirst(1)
    // 4 더 나은 사용자 경험을 제공하기 위해 debounce(for:scheduler:)을 사용합니다. 그것이 없다면 fetchWeather는 입력된 모든 문자에 대해 새로운 HTTP 요청을 만들것입니다. debounce는 사용자가 입력을 멈추고 마지막 값을 전달할때까지 0.5초 동안 기다리다가 동작합니다. 이 동작에 대한 훌륭한 시각화를 RxMarbles에서 볼수 있습니다. 또한 인자로 scheduler을 전달하는 것은, 특정 큐에서 모든 값이 내보내지는 것을 의미합니다. 경험상(Rule of thumb), 백그라운드 큐(background queue)에서 값을 처리하고 메인 큐(main queue)에 전달해야 합니다.
      .debounce(for: .seconds(0.5), scheduler: scheduler)
    // 5 마지막으로, sink(receiveValue:)를 통해서 해당 이벤트를 관찰하고 이전에 구현했던 fetchWeather(forCity:)로 처리합니다.
      .sink(receiveValue: fetchWeather(forCity:))
  }
  
  func fetchWeather(forCity city: String) {
    // 1 OpenWeatherMap API로 부터 정보를 가져오는 새로운 요청을 만드는 것부터 시작합니다. 도시 이름을 인자(argument)로 전달합니다
    self.weatherFetcher.weeklyWeatherForecast(forCity: city) .map { response in
      // 2 응답받은 것(WeeklyForecastResponse 객체)을 DailyWeatherRowViewModel 객체의 배열로 매핑합니다. 해당 요소(entity)는 목록에서 한 행(row)을 나타냅니다. DailyWeatherRowViewModel.swift에 있는 곳에서 구현을 확인 할 수 있습니다. MVVM에서, 필요한 데이터를 정확하게 View에 보여주는 ViewModel 레이어가 가장 중요합니다. View에 WeeklyForecastResponse를 직접 노출하는 것은 말이 안되며, View 레이어가 그것을 사용하기 위해 모델을 강제로 구성(format)하기 때문입니다. View는 가능한 모르게 만들고 랜더링 하는데만 집중하도록 하는 것이 좋은 생각입니다.
      response.list.map(DailyWeatherRowViewModel.init)
    }
      // 3 OpenWeatherMap API는 하루에 시간에 따라 여러개의 온도를 반환하므로, 중복되는 것을 제거합니다. 이를 어떻게 하는지는 Array+Filtering.swift에서 확인 할 수 있습니다.
      .map(Array.removeDuplicates)
      // 4 서버로부터 데이터를 가져오거나 JSON의 blob로 파싱하는 것이 백그라운드 큐(background queue)에서 수행하지만, UI 업데이트 하는 것은 반드시 메인 큐(main queue)에서 수행해야 합니다. receive(on:)에서, 5, 6, 7 단계에서 수행한 업데이트가 올바른 위치에서 수행하는지를 확인합니다.
      .receive(on: DispatchQueue.main)
      // 5 sink(receiveCompletion:receiveValue:)를 사용해서 게시자(publisher)를 시작합니다. 이곳에서 dataSource를 적절하게 업데이트 합니다. 값을 처리하는 것과는 별개로 -성공이나 실패중 하나에 대한- 완료(completion)를 처리하는 것이 중요합니다.
      .sink( receiveCompletion: { [weak self] value in
        guard let self = self else { return }
        switch value {
        case .failure:
          // 6 이벤트가 실패한 경우에,dataSource는 비어있는 배열을 설정합니다.
          self.dataSource = []
        case .finished:
          break
          
        }
        }, receiveValue: { [weak self] forecast in
          guard let self = self else { return }
          // 7 새로운 날씨가 도착할때 dataSource를 업데이트 합니다.
          self.dataSource = forecast
          
      })
      // 8 마지막으로, disposable 설정에 취소가능한 참조를 추가합니다. 이전에 언급했던 것처럼, 참조를 유지하지 않고, 네트워크 게시자(publisher)는 즉시 종료할 것입니다.
      .store(in: &disposables)
  }
  
}
