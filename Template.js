Highcharts.chart('container', {
    chart: {
        type: 'line',
    },
    
    title: {
        text: 'CASH HELPER CHART VIEW',
        align: 'left'
    },

    subtitle: {
        text: 'A graphic resume of your sells',
        align: 'left'
    },

    yAxis: {
        title: {
            text: 'Amount in millims'
        }
    },

    xAxis: {
        categories: ['2023/02/21','2023/02/25','2023/03/04','2023/03/05','2023/06/01','2023/06/02','2023/06/03','2023/06/04'],
    },

    series: [{
        name: 'SELLS',
        color: '#008000',
        data: [29550,31250,6000,45250,475650,540450,572000,264550],
    }, {
        name: 'COSTS',
        color: '#FF0000',
        data: [25984,25926,4913,39566,411282,460238,482860,224345]
    }, {
        name: 'PROFITS',
        color: '#0066FF',
        data: [3566,5324,1087,5684,64368,80212,89140,40205]
    }],

    responsive: {
        rules: [{
            condition: {
                maxWidth: 500
            },
            chartOptions: {
                legend: {
                    layout: 'horizontal',
                    align: 'center',
                    verticalAlign: 'bottom'
                }
            }
        }]
    }

});
