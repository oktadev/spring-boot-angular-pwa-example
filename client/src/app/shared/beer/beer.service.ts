import { Injectable } from '@angular/core';
import { Http, RequestOptions, Response, Headers } from '@angular/http';
import 'rxjs/add/operator/map';
import { Observable } from 'rxjs';
import { OktaAuthService } from '@okta/okta-angular';

@Injectable()
export class BeerService {

  constructor(private http: Http, private oktaAuth: OktaAuthService) {
  }

  getAll(): Observable<any> {
    const headers: Headers = new Headers();
    if (this.oktaAuth.isAuthenticated()) {
      const accessToken = this.oktaAuth.getAccessToken().accessToken;
      headers.append('Authorization', accessToken.tokenType + ' ' + accessToken.accessToken);
    }
    const options = new RequestOptions({headers: headers});

    return this.http.get('http://localhost:8080/good-beers', options)
      .map((response: Response) => response.json());
  }
}
