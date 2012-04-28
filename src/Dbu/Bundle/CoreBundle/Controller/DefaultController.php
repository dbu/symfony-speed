<?php

namespace Dbu\Bundle\CoreBundle\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\Controller;


class DefaultController extends Controller
{

    public function indexAction()
    {
        usleep(300); // simulate a lot of heavy work so that varnish has some effect.
        return $this->render('DbuCoreBundle:Default:index.html.twig', array());
    }
}
