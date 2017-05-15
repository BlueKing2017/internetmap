package com.peer1.internetmap.network.common;

import com.peer1.internetmap.models.ASN;
import com.peer1.internetmap.models.GlobalIP;

import retrofit2.Call;
import retrofit2.http.GET;
import retrofit2.http.Path;

/**
 * Created by shayla on 2017-05-10.
 */


public interface CommonAPI {

    /**
     * Using https://www.ipify.org/ to grab external IP
     * As of 2017-05-10, service was free for use without limit
     */
    @GET("https://api.ipify.org?format=json")
    Call<GlobalIP> getGlobalIP();

    /**
     * https://iptoasn.com/
     * Free IP address to ASN database
     * Can also download DB and run local service
     */
    @GET("https://api.iptoasn.com/v1/as/ip/{ip}")
    Call<ASN> getASNFromIP(@Path("ip") String ip);

    // TODO
    //@GET("https://api.iptoasn.com/v1/as/ip/{ip}")
    //Call<ASN> getIPFromASN(@Path("ip") String ip);

}
