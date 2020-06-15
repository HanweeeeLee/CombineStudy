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

import Foundation
import Combine

protocol WeatherFetchable {
  func weeklyWeatherForecast(forCity city: String) -> AnyPublisher<WeeklyForecastResponse, WeatherError>
  func currentWeatherForecast(forCity city: String) -> AnyPublisher<CurrentWeatherForecastResponse, WeatherError>
}

class WeatherFetcher {
  private let session: URLSession
  
  init(session: URLSession = .shared) {
    self.session = session
  }
}

// MARK: - OpenWeatherMap API
private extension WeatherFetcher {
  struct OpenWeatherAPI {
    static let scheme = "https"
    static let host = "api.openweathermap.org"
    static let path = "/data/2.5"
    static let key = "ed30f1d93596934d60d66e095f34b2ce"
  }
  
  func makeWeeklyForecastComponents(
    withCity city: String
  ) -> URLComponents {
    var components = URLComponents()
    components.scheme = OpenWeatherAPI.scheme
    components.host = OpenWeatherAPI.host
    components.path = OpenWeatherAPI.path + "/forecast"
    
    components.queryItems = [
      URLQueryItem(name: "q", value: city),
      URLQueryItem(name: "mode", value: "json"),
      URLQueryItem(name: "units", value: "metric"),
      URLQueryItem(name: "APPID", value: OpenWeatherAPI.key)
    ]
    
    return components
  }
  
  func makeCurrentDayForecastComponents(
    withCity city: String
  ) -> URLComponents {
    var components = URLComponents()
    components.scheme = OpenWeatherAPI.scheme
    components.host = OpenWeatherAPI.host
    components.path = OpenWeatherAPI.path + "/weather"
    
    components.queryItems = [
      URLQueryItem(name: "q", value: city),
      URLQueryItem(name: "mode", value: "json"),
      URLQueryItem(name: "units", value: "metric"),
      URLQueryItem(name: "APPID", value: OpenWeatherAPI.key)
    ]
    
    return components
  }
}

// MARK: - WeatherFetchable

extension WeatherFetcher: WeatherFetchable {
  func weeklyWeatherForecast(forCity city: String) -> AnyPublisher<WeeklyForecastResponse, WeatherError> {
    return forecast(with: makeWeeklyForecastComponents(withCity: city))
  }
  
  func currentWeatherForecast(forCity city: String) -> AnyPublisher<CurrentWeatherForecastResponse, WeatherError> {
    return forecast(with: makeCurrentDayForecastComponents(withCity: city))
  }
  
  private func forecast<T>(with components: URLComponents) -> AnyPublisher<T, WeatherError> where T: Decodable {
    // 1 URLComponents로 부터 URL 인스턴스를 만들려고 합니다. 만약 실패하면, Fail 값으로 감싸진 오류를 반환합니다. 그리고나서, 해당 타입을 지우고 메소드 반환 타입인 AnyPublisher에 타입을 지웁니다.
    guard let url = components.url else {
      let error = WeatherError.network(description: "Couldn't create URL")
      return Fail(error: error).eraseToAnyPublisher()
    }
    // 2 데이터를 가져오기 위해 URLSession의 새로운 메소드 dataTaskPublisher(for:)를 사용합니다. 이 메소드는 URLRequest의 인스턴스를 가지고 튜플 (Data, URLResponse) 또는 URLError중 하나를 반환합니다.
     return session.dataTaskPublisher(for: URLRequest(url: url))
    // 3 메소드가 AnyPublisher<T, WeatherError>를 반환하기 때문에, URLError에서 WeatherError로 오류를 매핑합니다.
      .mapError { error in .network(description: error.localizedDescription) }
    // 4 flatMap 사용은 자체적으로 사용할만 합니다. 여기에서 여러분은 서버에서 오는 JSON 데이터를 완전한 개게로 변환하기 위해 flatmap을 사용합니다. 이를 위한 보조기능으로 decode(_:)를 사용합니다. 네트워크 요청으로 받은 첫번째 값에만 관심이 있기에, .max(1)을 설정합니다.
      .flatMap(maxPublishers: .max(1)) {
        pair in decode(pair.data)
        
    } //5eraseToAnyPublisher()을 사용하지 않는 경우에 flatMap에서 반환된 전체 타입을 처리해야 합니다 : Publishers.FlatMap<AnyPublisher<_, WeatherError>, Publishers.MapError<URLSession.DataTaskPublisher, WeatherError>>. API 소비자로서, 여러분은 이런 자세한 내용으로 부담을 느끼고 싶지 않습니다. 따라서 API 인체공학을 개선하기 위해, AnyPublisher에 타입을 지웁니다. 이것은 또한 새로운 변환(예를 들어 filter)을 추가하면 반환된 타입을 변경하고 세부정보가 유출되기 때문에 유용합니다.
      .eraseToAnyPublisher()
  }
  
}
