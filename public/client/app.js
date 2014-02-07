// ------------ Write and expose app ------------ //

var app = angular.module("ShortlyApp", ['ngRoute']);

// --------------- Do some stuff ---------------- //

app.run(function($rootScope){
});

// ------------- Create App Routes -------------- //

app.config(function($routeProvider){
  $routeProvider
    .when('/', {
      controller: 'LinksController',
      templateUrl: "/templates/home.html"
    })
    .when('/shorten', {
      controller: 'ShortenController',
      templateUrl: "/templates/home.html"
    })
    .otherwise({
      redirectTo: '/'
    });  
});

// ---------- Write Controller Logic ------------ //

app.controller('LinksController', function($scope, $http){
  $http({
    method: "GET",
    url: "/links"
  })
  .success(function(data, status){
    $scope.links = data;
  })
  .error(function(err, status){
    $console.log('err', err);
    $scope.links = 'There was an error';
  });
});

app.controller('ShortenController', function($scope, $http){

});