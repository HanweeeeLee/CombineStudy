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

struct WeeklyWeatherView: View {
  
  @ObservedObject var viewModel: WeeklyWeatherViewModel
  
  init(viewModel: WeeklyWeatherViewModel) {
    self.viewModel = viewModel
  }
  
//  var body: some View {
//    NavigationView {
//      VStack {
//        NavigationLink(
//          "Best weather app :] ⛅️",
//          destination: CurrentWeatherView()
//        )
//      }
//    }
//  }
  var body: some View {
    NavigationView {
      List {
        
        searchField
        
        if viewModel.dataSource.isEmpty {
          emptySection
        }
        else {
          cityHourlyWeatherSection
          forecastSection
        }
      }
      .listStyle(GroupedListStyle())
      .navigationBarTitle("Weather ⛅️")
    }
  }
}

private extension WeeklyWeatherView {
  
  var searchField: some View {
    HStack(alignment: .center)
    {
      // 1 첫번째 바인딩(bind)! $viewModel.city은 TextField에 입력된 값과 WeeklyWeatherViewModel의 city 프로퍼티 간의 연결을 설정합니다. $을 사용해서 city 프로퍼티를 Binding<String>으로 만듭니다. 이는 WeeklyWeatherViewModel이 ObservableObject를 준수하기 때문에 가능하고 @ObservedObject 프로퍼티 래퍼(property wrapper)로 선언됬습니다.
      TextField("e.g. Cupertino", text: $viewModel.city)
    }
  }
  
  var forecastSection: some View {
    Section
      {
        // 2 자체 ViewModels을 사용해서 일일 기상 예보 행을 초기화합니다. 어떻게 동작하는지 보기 위해서 DailyWeatherRow.swift을 열어주세요.
        ForEach(viewModel.dataSource, content: DailyWeatherRow.init(viewModel:))
    }
  }
  
  var cityHourlyWeatherSection: some View {
    Section
      {
        NavigationLink(destination: CurrentWeatherView())
        {
          VStack(alignment: .leading)
          {
            // 3 어떤 바인딩 없이, WeeklyWeatherViewModel 프로퍼티들을 계속 사용하고 접근할수 있습니다. 이것은 Text로 도시 이름을 보여줍니다
            Text(viewModel.city)
            Text("Weather today")
              .font(.caption)
              .foregroundColor(.gray)
          }
        }
    }
  }
  
  var emptySection: some View {
    Section
      {
        Text("No results")
          .foregroundColor(.gray)
    }
  }
  
}

